import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';

part 'circles_state.dart';

@injectable
class CirclesCubit extends Cubit<CirclesState> {
  CirclesCubit(this._watchCircles) : super(const CirclesLoading()) {
    _subscription = _watchCircles().listen((circles) {
      final sharedCircles = circles.where((c) => c.isShared).toList();
      emit(
        sharedCircles.isEmpty
            ? const CirclesEmpty()
            : CirclesLoaded(sharedCircles),
      );
    }, onError: (Object error) => emit(CirclesError('$error')));
  }

  final WatchCirclesUseCase _watchCircles;
  StreamSubscription<List<CircleBook>>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
