import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/zap_earnings_service.dart';

@injectable
class EarningsCubit extends Cubit<int> {
  EarningsCubit(this._earnings) : super(_earnings.totalEarned.value) {
    _earnings.totalEarned.addListener(_onChanged);
  }

  final ZapEarningsService _earnings;

  void _onChanged() {
    if (!isClosed) emit(_earnings.totalEarned.value);
  }

  @override
  Future<void> close() {
    _earnings.totalEarned.removeListener(_onChanged);
    return super.close();
  }
}
