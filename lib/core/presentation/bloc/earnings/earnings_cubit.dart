import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@injectable
class EarningsCubit extends Cubit<int> {
  EarningsCubit(this._earningsDao, this._identity) : super(0) {
    _init();
  }

  final ZapSatsEarningsDao _earningsDao;
  final IdentityLocalDataSource _identity;
  StreamSubscription<int>? _sub;

  void _init() async {
    final npub = await _identity.readNpub() ?? '';
    final initial = await _earningsDao.getTotalSats(npub);
    if (!isClosed) emit(initial);

    _sub = _earningsDao.watchTotalSats(npub).listen((total) {
      if (!isClosed) emit(total);
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
