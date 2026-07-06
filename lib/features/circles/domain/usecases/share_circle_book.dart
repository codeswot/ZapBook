import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/services/circle_share_service.dart';
import 'package:zapbook/core/services/group_envelope_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/group_store_service.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';

@injectable
class ShareCircleBookUseCase {
  ShareCircleBookUseCase(
    this._keyPackageService,
    this._envelopeService,
    this._shareService,
    this._circleStore,
    this._groupStore,
  );

  final KeyPackageService _keyPackageService;
  final GroupEnvelopeService _envelopeService;
  final CircleShareService _shareService;
  final CircleStoreService _circleStore;
  final GroupStoreService _groupStore;
  final _log = logging.Logger('ShareCircleBookUseCase');
  Future<List<ShareSkip>> call({
    required String circleBookId,
    required List<String> npubs,
    required String myNpub,
  }) async {
    final book = _circleStore.currentCircles
        .where((b) => b.id == circleBookId)
        .firstOrNull;
    if (book == null) return [];

    final groupId = book.id;
    final skips = <ShareSkip>[];

    for (final npub in npubs) {
      try {
        final keyPackageJson = await _keyPackageService.fetchKeyPackage(npub);
        if (keyPackageJson == null) {
          _log.warning('No key package found for $npub');
          skips.add(
            ShareSkip(npub: npub, reason: ShareSkipReason.noKeyPackage),
          );
          continue;
        }

        final result = await _circleStore.addCircleMember(
          groupId,
          keyPackageJson,
        );
        if (result == null) {
          _log.warning('Failed to add member $npub');
          skips.add(
            ShareSkip(npub: npub, reason: ShareSkipReason.unknownError),
          );
          continue;
        }

        final hex = await MarmotIdentity.pubkeyHexFromNpub(npub);
        for (final rumorJson in result.welcomeRumors) {
          await _envelopeService.giftWrapAndPublish(rumorJson, hex);
        }
      } catch (e, stack) {
        _log.severe('Failed to add member', e, stack);
        skips.add(ShareSkip(npub: npub, reason: ShareSkipReason.unknownError));
      }
    }

    if (skips.length < npubs.length) {
      await _shareService.uploadBookContent(myNpub, groupId, circleBookId);
      await _groupStore.refreshGroup(groupId);
    }

    return skips;
  }
}
