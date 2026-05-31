import 'package:equatable/equatable.dart';
import 'package:zapbook/zbf/zbf.dart';

class ZbfViewerState extends Equatable {
  const ZbfViewerState({
    this.currentPage = 0,
    this.refinedPages = const {},
    this.refiningPages = const {},
    this.updateTrigger = 0,
  });

  final int currentPage;
  final Map<int, List<BookBlock>> refinedPages;
  final Set<int> refiningPages;
  final int updateTrigger;

  ZbfViewerState copyWith({
    int? currentPage,
    Map<int, List<BookBlock>>? refinedPages,
    Set<int>? refiningPages,
    int? updateTrigger,
  }) {
    return ZbfViewerState(
      currentPage: currentPage ?? this.currentPage,
      refinedPages: refinedPages ?? this.refinedPages,
      refiningPages: refiningPages ?? this.refiningPages,
      updateTrigger: updateTrigger ?? this.updateTrigger,
    );
  }

  @override
  List<Object?> get props => [currentPage, refinedPages, refiningPages, updateTrigger];
}
