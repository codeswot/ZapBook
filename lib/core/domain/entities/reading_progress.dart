import 'package:equatable/equatable.dart';

class ReadingProgress extends Equatable {
  const ReadingProgress({
    required this.pubKey,
    required this.bookId,
    required this.page,
    required this.fraction,
    required this.updatedAt,
    this.milestonesReached = 0,
    this.completed = false,
  });

  final String pubKey;
  final String bookId;
  final int page;
  final double fraction;
  final int updatedAt;
  final int milestonesReached;
  final bool completed;

  @override
  List<Object?> get props => [
    pubKey,
    bookId,
    page,
    fraction,
    updatedAt,
    milestonesReached,
    completed,
  ];
}
