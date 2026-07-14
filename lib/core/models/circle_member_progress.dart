import 'package:equatable/equatable.dart';
import 'package:zapbook/core/models/app_message.dart';

class CircleMemberProgress extends Equatable {
  final String groupId;
  final String pubKey;
  final String bookId;
  final int pageIndex;
  final double progressPercentage;
  final int updatedAt;
  final int milestonesReached;
  final bool completed;

  const CircleMemberProgress({
    required this.groupId,
    required this.pubKey,
    required this.bookId,
    required this.pageIndex,
    required this.progressPercentage,
    required this.updatedAt,
    this.milestonesReached = 0,
    this.completed = false,
  });

  factory CircleMemberProgress.fromAppMessage(BookProgressMessage msg) {
    return CircleMemberProgress(
      groupId: msg.groupId,
      pubKey: msg.senderNpub,
      bookId: msg.payload['circleDirId'] as String? ?? '',
      pageIndex: msg.payload['currentPage'] as int? ?? 0,
      progressPercentage: (msg.payload['fraction'] as num?)?.toDouble() ?? 0.0,
      updatedAt: msg.timestampSecs,
      milestonesReached:
          (msg.payload['milestonesReached'] as num?)?.toInt() ?? 0,
      completed: msg.payload['bookCompleted'] as bool? ?? false,
    );
  }

  factory CircleMemberProgress.fromRow(Map<String, dynamic> row) {
    return CircleMemberProgress(
      groupId: row['group_id'] as String,
      pubKey: row['pub_key'] as String,
      bookId: row['book_id'] as String,
      pageIndex: row['page_index'] as int,
      progressPercentage: (row['progress_percentage'] as num).toDouble(),
      updatedAt: row['updated_at'] as int,
      milestonesReached: (row['milestones_reached'] as num?)?.toInt() ?? 0,
      completed: ((row['completed'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  @override
  List<Object?> get props => [
    groupId,
    pubKey,
    bookId,
    pageIndex,
    progressPercentage,
    updatedAt,
    milestonesReached,
    completed,
  ];
}
