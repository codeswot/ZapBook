import 'package:equatable/equatable.dart';

final class HomeDashboardBook extends Equatable {
  const HomeDashboardBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverPath,
    required this.pageCount,
    required this.memberCount,
    required this.zbfPath,
    this.lastOpenedAt,
    this.currentPage = 0,
    this.totalWords = 0,
    this.currentWordCount = 0,
    this.fraction = 0,
  });

  final String id;
  final String title;
  final String author;
  final String? coverPath;
  final int pageCount;
  final int memberCount;
  final String zbfPath;
  final DateTime? lastOpenedAt;
  final int currentPage;
  final int totalWords;
  final int currentWordCount;
  final double fraction;

  bool get isShared => memberCount > 1;

  double get progressFraction => fraction;

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    coverPath,
    pageCount,
    memberCount,
    zbfPath,
    lastOpenedAt,
    currentPage,
    totalWords,
    currentWordCount,
    fraction,
  ];
}

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
  const HomeDashboard({required this.stats, required this.books});

  final HomeDashboardStats stats;
  final List<HomeDashboardBook> books;

  @override
  List<Object?> get props => [stats, books];
}
