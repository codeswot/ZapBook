import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/usecases/earnings_usecases.dart';

@injectable
class EarningsCubit extends Cubit<int> {
  EarningsCubit(this._getEarnings, this._watchEarnings) : super(0) {
    _init();
  }

  final GetEarningsUseCase _getEarnings;
  final WatchEarningsUseCase _watchEarnings;
  StreamSubscription<int>? _sub;

  void _init() async {
    final initial = await _getEarnings();
    if (!isClosed) emit(initial);

    _sub = _watchEarnings().listen((total) {
      if (!isClosed) emit(total);
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
