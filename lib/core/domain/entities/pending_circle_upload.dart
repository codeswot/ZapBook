import 'package:equatable/equatable.dart';

final class PendingCircleUpload extends Equatable {
  const PendingCircleUpload({
    required this.circleDirId,
    required this.groupId,
    required this.ownerNpub,
    required this.attempts,
    required this.updatedAt,
    this.failureReason,
  });

  final String circleDirId;
  final String groupId;
  final String ownerNpub;
  final int attempts;
  final DateTime updatedAt;
  final String? failureReason;

  @override
  List<Object?> get props => [
    circleDirId,
    groupId,
    ownerNpub,
    attempts,
    updatedAt,
    failureReason,
  ];
}
