import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/services/circle_store_service.dart';

part 'circles_state.dart';

@injectable
class CirclesCubit extends Cubit<CirclesState> {
  CirclesCubit(this._circleStore) : super(const CirclesLoading()) {
    _subscription = _circleStore.watchCircleBooks.listen((circles) {
      final sharedCircles = circles.where((c) => c.isShared).toList();
      emit(
        sharedCircles.isEmpty
            ? const CirclesEmpty()
            : CirclesLoaded(sharedCircles),
      );
    }, onError: (Object error) => emit(CirclesError('$error')));
  }

  final CircleStoreService _circleStore;
  StreamSubscription<List<CircleBook>>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
