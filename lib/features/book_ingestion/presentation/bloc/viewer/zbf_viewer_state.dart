import 'package:equatable/equatable.dart';
import 'package:zapbook/zbf/zbf.dart';

class ZbfViewerState extends Equatable {
  const ZbfViewerState({
    this.currentPage = 0,
    this.imagePages = const {},
    this.rasterizingPages = const {},
    this.updateTrigger = 0,
  });

  final int currentPage;

  /// Pages rendered as a rasterized page image (illustration / sparse-text
  /// pages). Keyed by global page index; value is the block list to render
  /// (a leading [ImageBlock] followed by any extracted draft blocks).
  final Map<int, List<BookBlock>> imagePages;

  /// Pages currently being rasterized in the background.
  final Set<int> rasterizingPages;

  final int updateTrigger;

  ZbfViewerState copyWith({
    int? currentPage,
    Map<int, List<BookBlock>>? imagePages,
    Set<int>? rasterizingPages,
    int? updateTrigger,
  }) {
    return ZbfViewerState(
      currentPage: currentPage ?? this.currentPage,
      imagePages: imagePages ?? this.imagePages,
      rasterizingPages: rasterizingPages ?? this.rasterizingPages,
      updateTrigger: updateTrigger ?? this.updateTrigger,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    imagePages,
    rasterizingPages,
    updateTrigger,
  ];
}
