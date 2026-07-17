import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';

@lazySingleton
class ZapNudgeService {
  ZapNudgeService(this._marmot, this._identity, this._envelope, this._prefs);

  final Marmot _marmot;
  final IdentityLocalDataSource _identity;
  final GroupEnvelopeService _envelope;
  final SharedPreferences _prefs;

  final _log = logging.Logger('ZapNudgeService');
  static const _nudgeKeyPrefix = 'zap_nudge_last_ms_';
  static const _nudgeCooldown = Duration(hours: 24);

  Future<void> clearNudge(String npub) async {
    await _prefs.remove('$_nudgeKeyPrefix$npub');
  }

  Future<void> nudge({required String groupId, required String toNpub}) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final nudgeKey = '$_nudgeKeyPrefix$toNpub';
    final lastMs = _prefs.getInt(nudgeKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastMs < _nudgeCooldown.inMilliseconds) return;
    await _prefs.setInt(nudgeKey, nowMs);

    final nudgeId = '$npub:$toNpub:${DateTime.now().millisecondsSinceEpoch}';
    await _send(npub, groupId, {
      'type': AppMessageTypes.zapNudge,
      'nudgeId': nudgeId,
      'fromNpub': npub,
      'toNpub': toNpub,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> ready({
    required String groupId,
    required String nudgeId,
    required String toNpub,
  }) async {
    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;
    await _send(npub, groupId, {
      'type': AppMessageTypes.zapReady,
      'nudgeId': nudgeId,
      'fromNpub': npub,
      'toNpub': toNpub,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _send(
    String npub,
    String groupId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final event = await _marmot.sendStructured(npub, groupId, payload);
      _envelope.publish(event);
    } on Object catch (error, stack) {
      _log.warning('Nudge send failed', error, stack);
    }
  }
}
