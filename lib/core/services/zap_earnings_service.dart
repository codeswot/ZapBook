import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';

@lazySingleton
class ZapEarningsService {
  ZapEarningsService(this._ndk);

  final Ndk _ndk;
  final _log = logging.Logger('ZapEarningsService');

  static const _nutzapKind = 9321;
  static const _pageSize = 200;
  static const _maxPages = 25;

  final _total = ValueNotifier<int>(0);
  final _byCircle = <String, int>{};
  final _countedIds = <String>{};
  final _subs = <StreamSubscription<Nip01Event>>[];
  final _requestIds = <String>[];
  int _sum = 0;
  bool _started = false;

  ValueListenable<int> get totalEarned => _total;

  int earnedForCircle(String circleId) => _byCircle[circleId] ?? 0;

  Future<void> start() async {
    if (_started) return;
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;
    _started = true;

    await _backfill(pubkey, ZapReceipt.kKind, _ingestReceipt);
    await _backfill(pubkey, _nutzapKind, _ingestNutzap);
    _listen(pubkey, ZapReceipt.kKind, _ingestReceipt);
    _listen(pubkey, _nutzapKind, _ingestNutzap);
  }

  Future<void> _backfill(
    String pubkey,
    int kind,
    bool Function(Nip01Event) ingest,
  ) async {
    try {
      var changed = false;
      int? until;
      for (var page = 0; page < _maxPages; page++) {
        final events = await _ndk.requests
            .query(
              filter: Filter(
                kinds: [kind],
                pTags: [pubkey],
                until: until,
                limit: _pageSize,
              ),
            )
            .future;
        if (events.isEmpty) break;
        for (final event in events) {
          if (ingest(event)) changed = true;
        }
        final oldest = events
            .map((e) => e.createdAt)
            .reduce((a, b) => a < b ? a : b);
        final next = oldest - 1;
        if (until != null && next >= until) break;
        until = next;
        if (events.length < _pageSize) break;
      }
      if (changed) _emit();
    } catch (error, trace) {
      _log.info('backfill kind $kind $error', trace);
    }
  }

  void _listen(String pubkey, int kind, bool Function(Nip01Event) ingest) {
    try {
      final response = _ndk.requests.subscription(
        filter: Filter(kinds: [kind], pTags: [pubkey]),
      );
      _requestIds.add(response.requestId);
      _subs.add(
        response.stream.listen((event) {
          if (ingest(event)) _emit();
        }),
      );
    } catch (error, trace) {
      _log.info('listen kind $kind $error', trace);
    }
  }

  bool _ingestReceipt(Nip01Event event) {
    if (_countedIds.contains(event.id)) return false;
    final requestTags = _embeddedRequestTags(event);
    if (requestTags == null || !_isZapbook(requestTags)) return false;
    var sats = _bolt11Sats(_firstTagValue(event, 'bolt11'));
    if (sats <= 0) sats = _requestAmountSats(requestTags);
    if (sats <= 0) return false;
    _countedIds.add(event.id);
    _add(sats, _circleId(requestTags));
    return true;
  }

  bool _ingestNutzap(Nip01Event event) {
    if (_countedIds.contains(event.id)) return false;
    final sats = _nutzapSats(event);
    if (sats <= 0) return false;
    _countedIds.add(event.id);
    _add(sats, null);
    return true;
  }

  void _add(int sats, String? circleId) {
    _sum += sats;
    if (circleId != null) {
      _byCircle[circleId] = (_byCircle[circleId] ?? 0) + sats;
    }
  }

  void _emit() => _total.value = _sum;

  int _bolt11Sats(String? bolt11) {
    if (bolt11 == null) return 0;
    try {
      final match = _bolt11Regexp.firstMatch(bolt11.toLowerCase());
      if (match == null) return 0;
      final base = int.parse(match.group(1)!);
      final btc = switch (match.group(2)!) {
        'm' => base * 0.001,
        'u' => base * 0.000001,
        'n' => base * 0.000000001,
        'p' => base * 0.000000000001,
        _ => base.toDouble(),
      };
      return (btc * 100000000).floor();
    } catch (_) {
      return 0;
    }
  }

  int _requestAmountSats(List requestTags) {
    final value = int.tryParse(_tagValue(requestTags, 'amount') ?? '');
    return value == null ? 0 : value ~/ 1000;
  }

  int _nutzapSats(Nip01Event event) {
    var msat = false;
    var total = 0;
    for (final tag in event.tags) {
      if (tag.length < 2) continue;
      if (tag[0] == 'unit') {
        msat = tag[1] == 'msat';
      } else if (tag[0] == 'proof') {
        try {
          final proof = jsonDecode(tag[1]);
          final amount = proof is Map ? proof['amount'] : null;
          if (amount is num) total += amount.toInt();
        } catch (_) {}
      }
    }
    return msat ? (total / 1000).round() : total;
  }

  List? _embeddedRequestTags(Nip01Event event) {
    final description = _firstTagValue(event, 'description');
    if (description == null || description.isEmpty) return null;
    try {
      return jsonDecode(description)['tags'] as List?;
    } catch (_) {
      return null;
    }
  }

  bool _isZapbook(List tags) => tags.any(
    (t) => t is List && t.length > 1 && t[0] == 'client' && t[1] == 'zapbook',
  );

  String? _circleId(List tags) {
    final value = _tagValue(tags, 'circle');
    return (value != null && value.isNotEmpty) ? value : null;
  }

  String? _tagValue(List tags, String name) {
    for (final t in tags) {
      if (t is List && t.length > 1 && t[0] == name && t[1] is String) {
        return t[1] as String;
      }
    }
    return null;
  }

  String? _firstTagValue(Nip01Event event, String name) {
    for (final t in event.tags) {
      if (t.length > 1 && t[0] == name) return t[1];
    }
    return null;
  }

  @disposeMethod
  void dispose() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    for (final id in _requestIds) {
      unawaited(_ndk.requests.closeSubscription(id));
    }
    _requestIds.clear();
    _total.dispose();
  }
}

final _bolt11Regexp = RegExp(r'lnbc(\d+)([munp])');
