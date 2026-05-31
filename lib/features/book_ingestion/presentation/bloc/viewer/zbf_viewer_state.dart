import 'package:equatable/equatable.dart';

class ZbfViewerState extends Equatable {
  const ZbfViewerState({this.currentPage = 0});

  final int currentPage;

  @override
  List<Object?> get props => [currentPage];
}
