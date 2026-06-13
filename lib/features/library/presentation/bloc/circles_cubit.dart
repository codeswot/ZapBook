import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/usecases/watch_circles.dart';
import 'package:zapbook/features/library/presentation/bloc/circles_state.dart';

@injectable
class CirclesCubit extends Cubit<CirclesState> {
  CirclesCubit(this._watchCircles) : super(const CirclesLoading()) {
    _subscription = _watchCircles().listen(
      (circles) =>
          emit(circles.isEmpty ? const CirclesEmpty() : CirclesLoaded(circles)),
      onError: (Object error) => emit(CirclesError('$error')),
    );
  }

  final WatchCircles _watchCircles;
  StreamSubscription<List<LibraryBook>>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
