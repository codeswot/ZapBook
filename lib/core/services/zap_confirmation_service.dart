import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/features/cheers/data/datasources/cheers_data_source.dart';

/// A single pending zap that has been sent to an external wallet but whose
/// receipt has not yet been confirmed on relays.
class PendingZapRecord {
  final String zapRequestId; // kind-9734 event ID
  final String invoice;       // bolt11 invoice
  final String recipientPubkey; // hex pubkey of receiver
  final String activityId;   // Marmot activity to record on confirmation
  final int amount;
  final String reactionType;
  final int createdAtMs;     // wall-clock epoch ms, used for TTL pruning

  const PendingZapRecord({
    required this.zapRequestId,
    required this.invoice,
    required this.recipientPubkey,
    required this.activityId,
    required this.amount,
    required this.reactionType,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() => {
    'zapRequestId': zapRequestId,
    'invoice': invoice,
    'recipientPubkey': recipientPubkey,
    'activityId': activityId,
    'amount': amount,
    'reactionType': reactionType,
    'createdAtMs': createdAtMs,
  };

  factory PendingZapRecord.fromJson(Map<String, dynamic> json) =>
      PendingZapRecord(
        zapRequestId: json['zapRequestId'] as String,
        invoice: json['invoice'] as String? ?? '',
        recipientPubkey: json['recipientPubkey'] as String? ?? '',
        activityId: json['activityId'] as String,
        amount: json['amount'] as int,
        reactionType: json['reactionType'] as String,
        createdAtMs: json['createdAtMs'] as int,
      );
}

@lazySingleton
class ZapConfirmationService {
  ZapConfirmationService(this._prefs, this._ndk, this._cheersDataSource);

  final SharedPreferences _prefs;
  final Ndk _ndk;
  final CheersDataSource _cheersDataSource;

  static const _prefsKey = 'pending_zap_records';
  static const _ttlDays = 3;
  static const _receiptRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
  ];

  final _log = logging.Logger('ZapConfirmationService');

  // Active subscription IDs keyed by zapRequestId
  final _activeSubs = <String, String>{};

  /// Call once on session start to re-subscribe for any persisted pending zaps.
  void resume() {
    _prune();
    for (final record in _load()) {
      _subscribe(record);
    }
  }

  /// Register a new pending zap immediately and start watching for its receipt.
  void watch(PendingZapRecord record) {
    _persist(record);
    _subscribe(record);
  }

  /// Cancel a pending zap (e.g. user manually dismissed it).
  void cancel(String zapRequestId) {
    final subId = _activeSubs.remove(zapRequestId);
    if (subId != null) {
      _ndk.requests.closeSubscription(subId);
    }
    _removePersisted(zapRequestId);
    _log.fine('Cancelled pending zap $zapRequestId');
  }

  void _subscribe(PendingZapRecord record) {
    if (_activeSubs.containsKey(record.zapRequestId)) return;
    if (record.recipientPubkey.isEmpty) {
      _log.warning('Cannot subscribe to pending zap with empty recipient pubkey');
      return;
    }

    final recipientHex = record.recipientPubkey.startsWith('npub')
        ? Nip19.decode(record.recipientPubkey)
        : record.recipientPubkey;

    final sub = _ndk.requests.subscription(
      filter: Filter(
        kinds: const [9735],
        tags: {
          '#p': [recipientHex],
        },
      ),
      explicitRelays: _receiptRelays,
    );

    _activeSubs[record.zapRequestId] = sub.requestId;

    final matchingEventFuture = sub.stream.firstWhere((event) {
      // Check for bolt11 tag matching the invoice
      final hasMatchingInvoice = event.tags.any((t) => t.length >= 2 && t[0] == 'bolt11' && t[1] == record.invoice);
      if (hasMatchingInvoice) return true;

      // Fallback: parse description tag
      try {
        final descTag = event.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'description');
        if (descTag.length >= 2) {
          final descJson = jsonDecode(descTag[1]) as Map<String, dynamic>;
          if (descJson['id'] == record.zapRequestId) {
            return true;
          }
        }
      } catch (_) {}

      return false;
    });

    matchingEventFuture.then((_) async {
      _log.info('Zap receipt confirmed for ${record.zapRequestId}');
      try {
        if (record.activityId.startsWith('direct:')) {
          final parts = record.activityId.split(':');
          if (parts.length >= 3) {
            final groupId = parts[1];
            final recipientNpub = parts[2];
            await _cheersDataSource.sendDirectZap(
              groupId,
              recipientNpub,
              record.amount,
              record.reactionType,
            );
          }
        } else {
          await _cheersDataSource.sendZap(
            record.activityId,
            record.amount,
            record.reactionType,
          );
        }
      } on Object catch (e, s) {
        _log.warning('sendZap after receipt failed', e, s);
      } finally {
        final subId = _activeSubs.remove(record.zapRequestId);
        if (subId != null) _ndk.requests.closeSubscription(subId);
        _removePersisted(record.zapRequestId);
      }
    }).catchError((Object e) {
      // stream closed without matching event, or cancelled
      _activeSubs.remove(record.zapRequestId);
    });
  }

  // ── Persistence helpers ─────────────────────────────────────────────────

  List<PendingZapRecord> _load() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PendingZapRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist(PendingZapRecord record) {
    final existing = _load()
      ..removeWhere((r) => r.zapRequestId == record.zapRequestId);
    existing.add(record);
    _prefs.setString(_prefsKey, jsonEncode(existing.map((r) => r.toJson()).toList()));
  }

  void _removePersisted(String zapRequestId) {
    final existing = _load()
      ..removeWhere((r) => r.zapRequestId == zapRequestId);
    _prefs.setString(_prefsKey, jsonEncode(existing.map((r) => r.toJson()).toList()));
  }

  void _prune() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: _ttlDays))
        .millisecondsSinceEpoch;
    final surviving = _load().where((r) => r.createdAtMs > cutoff).toList();
    _prefs.setString(_prefsKey, jsonEncode(surviving.map((r) => r.toJson()).toList()));
    _log.fine('Pruned ${_load().length - surviving.length} stale pending zaps');
  }
}
