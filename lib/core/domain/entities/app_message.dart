import 'dart:convert';
import 'package:marmot_dart/marmot_dart.dart';

abstract class AppMessageTypes {
  static const bookMeta = 'zapbook.book.meta';
  static const bookProgress = 'zapbook.book.progress';
  static const cheer = 'zapbook.cheer';
  static const zapNudge = 'zapbook.zap.nudge';
  static const zapReady = 'zapbook.zap.ready';
  static const zapSent = 'zapbook.zap.sent';
  static const reseedRequest = 'application/vnd.zapbook.reseed-request+json';
  static const highlightShared = 'zapbook.highlight.shared';
}

sealed class AppMessage {
  final MarmotMessage rawMessage;

  String get groupId => rawMessage.groupId;
  String get senderNpub => rawMessage.senderNpub;
  int get timestampSecs => rawMessage.timestampSecs;
  String get id => rawMessage.id;

  const AppMessage(this.rawMessage);

  static AppMessage? tryParse(MarmotMessage message) {
    if (message.payloadJson == null) return null;

    try {
      final decoded = jsonDecode(message.payloadJson!);
      final type = decoded['type'] as String? ?? message.contentType;

      if (type == null) return null;

      switch (type) {
        case AppMessageTypes.bookMeta:
          return InitialBookMessage(message, decoded);
        case AppMessageTypes.bookProgress:
          return BookProgressMessage(message, decoded);
        case AppMessageTypes.cheer:
          return CheersMessage(message, decoded);
        case AppMessageTypes.zapNudge:
          return ZapNudgeMessage(message, decoded);
        case AppMessageTypes.zapReady:
          return ZapReadyMessage(message, decoded);
        case AppMessageTypes.zapSent:
          return ZapSentMessage(message, decoded);
        case AppMessageTypes.reseedRequest:
          return ReseedRequestMessage(message, decoded);
        case AppMessageTypes.highlightShared:
          return HighlightSharedMessage(message, decoded);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

class InitialBookMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const InitialBookMessage(super.message, this.payload);
}

class BookProgressMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const BookProgressMessage(super.message, this.payload);
}

class BookCompletedMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const BookCompletedMessage(super.message, this.payload);
}

class CheersMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const CheersMessage(super.message, this.payload);
}

class ZapNudgeMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const ZapNudgeMessage(super.message, this.payload);
}

class ZapReadyMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const ZapReadyMessage(super.message, this.payload);
}

class ZapSentMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const ZapSentMessage(super.message, this.payload);
}

class ReseedRequestMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const ReseedRequestMessage(super.message, this.payload);
}

class HighlightSharedMessage extends AppMessage {
  final Map<String, dynamic> payload;

  const HighlightSharedMessage(super.message, this.payload);
}
