import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/viewer/zbf_viewer_state.dart';

class ZbfViewerCubit extends Cubit<ZbfViewerState> {
  ZbfViewerCubit() : super(const ZbfViewerState());

  void pageChanged(int index) {
    emit(ZbfViewerState(currentPage: index));
  }
}
