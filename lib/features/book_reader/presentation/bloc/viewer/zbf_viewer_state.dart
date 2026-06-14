import 'package:equatable/equatable.dart';
import 'package:zapbook/zbf/zbf.dart';

class ZbfViewerState extends Equatable {
  const ZbfViewerState({
    this.currentPage = 0,
    this.imagePages = const {},
    this.rasterizingPages = const {},
    this.failedPages = const {},
    this.updateTrigger = 0,
  });

  final int currentPage;

  final Map<int, List<BookBlock>> imagePages;

  final Set<int> rasterizingPages;

  final Set<int> failedPages;

  final int updateTrigger;

  ZbfViewerState copyWith({
    int? currentPage,
    Map<int, List<BookBlock>>? imagePages,
    Set<int>? rasterizingPages,
    Set<int>? failedPages,
    int? updateTrigger,
  }) {
    return ZbfViewerState(
      currentPage: currentPage ?? this.currentPage,
      imagePages: imagePages ?? this.imagePages,
      rasterizingPages: rasterizingPages ?? this.rasterizingPages,
      failedPages: failedPages ?? this.failedPages,
      updateTrigger: updateTrigger ?? this.updateTrigger,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    imagePages,
    rasterizingPages,
    failedPages,
    updateTrigger,
  ];
}
