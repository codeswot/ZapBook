import 'package:zapbook/core/models/app_message.dart';

abstract class MessageRouterService {
  Stream<InitialBookMessage> get onInitialBook;

  Stream<BookProgressMessage> get onProgress;

  Stream<MilestoneMessage> get onMilestone;

  Stream<BookCompletedMessage> get onBookCompleted;

  Stream<CheersMessage> get onCheers;

  Stream<ZapNudgeMessage> get onZapNudge;

  Stream<ZapReadyMessage> get onZapReady;

  Stream<ZapSentMessage> get onZapSent;

  void initialize();

  void dispose();
}
