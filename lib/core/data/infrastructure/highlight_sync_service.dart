import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/data/infrastructure/group_envelope_service.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/domain/entities/app_message.dart';
import 'package:zapbook/features/book_reader/domain/entities/highlight.dart';

@lazySingleton
class HighlightSyncService {
  HighlightSyncService(this._marmot, this._identity, this._envelope);

  final Marmot _marmot;
  final IdentityLocalDataSource _identity;
  final GroupEnvelopeService _envelope;
  final _log = logging.Logger('HighlightSyncService');

  Future<void> shareHighlight(Highlight highlight) async {
    final groupId = highlight.groupId;
    if (groupId == null || groupId.isEmpty) return;

    final npub = await _identity.readNpub();
    if (npub == null || npub.isEmpty) return;

    final payload = {
      'type': AppMessageTypes.highlightShared,
      'id': highlight.id,
      'bookId': highlight.bookId,
      'pageNumber': highlight.pageNumber,
      'spans': highlight.spans.map((s) => s.toJson()).toList(),
      'quoteSnapshot': highlight.quoteSnapshot,
      'note': highlight.note,
      'deleted': highlight.deleted,
      'sharedAtMs': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final event = await _marmot.sendStructured(npub, groupId, payload);
      await _envelope.publish(event);
    } on Object catch (error, stack) {
      _log.warning('Failed to share highlight', error, stack);
    }
  }
}
