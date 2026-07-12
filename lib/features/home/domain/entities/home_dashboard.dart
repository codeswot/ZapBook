import 'package:equatable/equatable.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';

final class HomeDashboardStats extends Equatable {
  const HomeDashboardStats({
    required this.dayStreak,
    required this.satsEarned,
    required this.booksRead,
  });

  final int dayStreak;
  final int satsEarned;
  final int booksRead;

  @override
  List<Object?> get props => [dayStreak, satsEarned, booksRead];
}

final class HomeDashboard extends Equatable {
  const HomeDashboard({
    required this.stats,
    required this.circles,
    this.lastOpenedCircleBook,
    this.lastOpenedProgress,
    this.lastOpenedPage,
  });

  final HomeDashboardStats stats;
  final List<CircleBook> circles;
  final CircleBook? lastOpenedCircleBook;
  final double? lastOpenedProgress;
  final int? lastOpenedPage;

  @override
  List<Object?> get props => [
    stats,
    circles,
    lastOpenedCircleBook,
    lastOpenedProgress,
    lastOpenedPage,
  ];
}
