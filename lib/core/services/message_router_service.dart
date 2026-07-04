import 'dart:async';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/models/app_message.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';

@LazySingleton()
class MessageRouterService {
  final MarmotSyncService _marmotSyncService;
  StreamSubscription<MarmotMessage>? _messageSub;

  final _initialBookController =
      StreamController<InitialBookMessage>.broadcast();
  final _progressController = StreamController<BookProgressMessage>.broadcast();
  final _milestoneController = StreamController<MilestoneMessage>.broadcast();
  final _bookCompletedController =
      StreamController<BookCompletedMessage>.broadcast();
  final _cheersController = StreamController<CheersMessage>.broadcast();
  final _zapNudgeController = StreamController<ZapNudgeMessage>.broadcast();
  final _zapReadyController = StreamController<ZapReadyMessage>.broadcast();
  final _zapSentController = StreamController<ZapSentMessage>.broadcast();

  MessageRouterService(this._marmotSyncService) {
    initialize();
  }

  Stream<InitialBookMessage> get onInitialBook => _initialBookController.stream;

  Stream<BookProgressMessage> get onProgress => _progressController.stream;

  Stream<MilestoneMessage> get onMilestone => _milestoneController.stream;

  Stream<BookCompletedMessage> get onBookCompleted =>
      _bookCompletedController.stream;

  Stream<CheersMessage> get onCheers => _cheersController.stream;

  Stream<ZapNudgeMessage> get onZapNudge => _zapNudgeController.stream;

  Stream<ZapReadyMessage> get onZapReady => _zapReadyController.stream;

  Stream<ZapSentMessage> get onZapSent => _zapSentController.stream;

  void initialize() {
    _messageSub = _marmotSyncService.onMessage.listen(_handleRawMessage);
  }

  void _handleRawMessage(MarmotMessage rawMsg) {
    final parsed = AppMessage.tryParse(rawMsg);
    if (parsed == null) return;
    if (parsed is InitialBookMessage) {
      _initialBookController.add(parsed);
    } else if (parsed is BookProgressMessage) {
      _progressController.add(parsed);
    } else if (parsed is MilestoneMessage) {
      _milestoneController.add(parsed);
    } else if (parsed is BookCompletedMessage) {
      _bookCompletedController.add(parsed);
    } else if (parsed is CheersMessage) {
      _cheersController.add(parsed);
    } else if (parsed is ZapNudgeMessage) {
      _zapNudgeController.add(parsed);
    } else if (parsed is ZapReadyMessage) {
      _zapReadyController.add(parsed);
    } else if (parsed is ZapSentMessage) {
      _zapSentController.add(parsed);
    }
  }

  void dispose() {
    _messageSub?.cancel();
    _initialBookController.close();
    _progressController.close();
    _milestoneController.close();
    _bookCompletedController.close();
    _cheersController.close();
    _zapNudgeController.close();
    _zapReadyController.close();
    _zapSentController.close();
  }
}
