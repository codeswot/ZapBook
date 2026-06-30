import 'dart:async';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/models/app_message.dart';
import 'package:zapbook/core/services/marmot_sync_service.dart';
import 'package:zapbook/core/services/message_router_service.dart';

@LazySingleton(as: MessageRouterService)
class MessageRouterServiceImpl implements MessageRouterService {
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

  MessageRouterServiceImpl(this._marmotSyncService) {
    initialize();
  }

  @override
  Stream<InitialBookMessage> get onInitialBook => _initialBookController.stream;

  @override
  Stream<BookProgressMessage> get onProgress => _progressController.stream;

  @override
  Stream<MilestoneMessage> get onMilestone => _milestoneController.stream;

  @override
  Stream<BookCompletedMessage> get onBookCompleted =>
      _bookCompletedController.stream;

  @override
  Stream<CheersMessage> get onCheers => _cheersController.stream;

  @override
  Stream<ZapNudgeMessage> get onZapNudge => _zapNudgeController.stream;

  @override
  Stream<ZapReadyMessage> get onZapReady => _zapReadyController.stream;

  @override
  Stream<ZapSentMessage> get onZapSent => _zapSentController.stream;

  @override
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

  @override
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
