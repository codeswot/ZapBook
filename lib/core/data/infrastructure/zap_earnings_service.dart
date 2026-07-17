import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';

@lazySingleton
class ZapEarningsService {
  ZapEarningsService(this._ndk, this._earningsDao);

  final Ndk _ndk;
  final ZapSatsEarningsDao _earningsDao;
  final _log = logging.Logger('ZapEarningsService');

  static const _nutzapKind = 9321;

  final _subs = <StreamSubscription<Nip01Event>>[];
  final _requestIds = <String>[];
  bool _started = false;
  late final String _myNpub;

  final _zapController = StreamController<ZapSatsEarningsRecord>.broadcast();
  Stream<ZapSatsEarningsRecord> get onZap => _zapController.stream;

  Future<void> start() async {
    if (_started) return;
    final pubkey = _ndk.accounts.getPublicKey();
    if (pubkey == null) return;
    _started = true;
    _myNpub = Nip19.encodePubKey(pubkey);

    final lastFetched = await _earningsDao.getLastZapTimestamp(_myNpub);

    _listen(pubkey, ZapReceipt.kKind, _ingestReceipt, lastFetched);
    _listen(pubkey, _nutzapKind, _ingestNutzap, lastFetched);
  }

  void _listen(
    String pubkey,
    int kind,
    void Function(Nip01Event) ingest,
    int? since,
  ) {
    try {
      final response = _ndk.requests.subscription(
        filter: Filter(kinds: [kind], pTags: [pubkey], since: since),
      );
      _requestIds.add(response.requestId);
      _subs.add(
        response.stream.listen((event) {
          ingest(event);
        }),
      );
    } catch (error, trace) {
      _log.info('listen kind $kind $error', trace);
    }
  }

  void _ingestReceipt(Nip01Event event) {
    String? description;
    String? bolt11;

    for (final t in event.tags) {
      if (t.length > 1) {
        if (t[0] == 'description') {
          description = t[1] as String?;
        } else if (t[0] == 'bolt11') {
          bolt11 = t[1] as String?;
        }
      }
    }

    if (description == null || !description.contains('"zapbook"')) return;

    List? requestTags;
    try {
      requestTags = jsonDecode(description)['tags'] as List?;
    } catch (_) {}

    if (requestTags == null) return;

    bool isZapbook = false;
    String? amountStr;
    String? targetId;
    String? zapTargetType;

    for (final t in requestTags) {
      if (t is List && t.length > 1 && t[0] is String && t[1] is String) {
        final name = t[0] as String;
        final value = t[1] as String;
        if (name == 'client' && value == 'zapbook') {
          isZapbook = true;
        } else if (name == 'amount') {
          amountStr = value;
        } else if (name == 'e' || name == 'a') {
          targetId = value;
        } else if (name == 'zapType') {
          zapTargetType = value;
        }
      }
    }

    if (!isZapbook) return;

    var sats = _bolt11Sats(bolt11);
    if (sats <= 0) {
      final value = int.tryParse(amountStr ?? '');
      sats = value == null ? 0 : value ~/ 1000;
    }
    if (sats <= 0) return;

    final activityId = (targetId != null && targetId.isNotEmpty)
        ? targetId
        : 'profile';

    final zapType = zapTargetType == 'circle'
        ? ZapType.circle
        : zapTargetType == 'milestone'
        ? ZapType.milestone
        : ZapType.profile;

    final record = ZapSatsEarningsRecord(
      id: event.id,
      senderNpub: event.pubKey,
      activityId: activityId,
      zapType: zapType,
      sats: sats,
      timestamp: event.createdAt,
    );
    unawaited(_emitIfNew(record));
  }

  void _ingestNutzap(Nip01Event event) {
    final sats = _nutzapSats(event);
    if (sats <= 0) return;

    final record = ZapSatsEarningsRecord(
      id: event.id,
      senderNpub: event.pubKey,
      activityId: 'profile',
      zapType: ZapType.profile,
      sats: sats,
      timestamp: event.createdAt,
    );
    unawaited(_emitIfNew(record));
  }

  Future<void> _emitIfNew(ZapSatsEarningsRecord record) async {
    final inserted = await _earningsDao.insertZap(_myNpub, record);
    if (inserted) _zapController.add(record);
  }

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
  }
}

final _bolt11Regexp = RegExp(r'lnbc(\d+)([munp])');
