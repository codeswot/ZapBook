import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';

@injectable
class EarningsCubit extends Cubit<int> {
  EarningsCubit(this._earningsDao) : super(0) {
    _init();
  }

  final ZapSatsEarningsDao _earningsDao;
  StreamSubscription<int>? _sub;

  void _init() async {
    final initial = await _earningsDao.getTotalSats();
    if (!isClosed) emit(initial);

    _sub = _earningsDao.watchTotalSats().listen((total) {
      if (!isClosed) emit(total);
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
