import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/lnurl_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_state.dart';

@injectable
class DonateCubit extends Cubit<DonateState> {
  DonateCubit(this._zap) : super(const DonateReady());

  final ZapService _zap;
  final _log = logging.Logger('DonateCubit');

  String get recipient => ZapbookConfig.lnAddress;

  static const _donationMessages = {
    ZapGesture.thumbsUp: 'Well done',
    ZapGesture.clap: 'ZapBook is awesome',
    ZapGesture.fire: 'Keep building ZapBook',
    ZapGesture.rocket: 'ZapBook To the moon!',
    ZapGesture.trophy: 'Absolutely legendary!',
  };

  void toggleGift() {
    switch (state) {
      case DonateReady(showGift: final g):
        emit(DonateReady(showGift: !g));
      case DonateFailure(showGift: final g, userMessage: final m):
        emit(DonateFailure(showGift: !g, userMessage: m));
      case _:
        break;
    }
  }

  Future<void> sendPreset(ZapGesture gesture) async {
    final showGift = switch (state) {
      DonateReady(showGift: final g) => g,
      DonateFailure(showGift: final g) => g,
      _ => false,
    };
    emit(DonateLoading(showGift: showGift, presetChip: gesture));

    try {
      final result = await _zap.donate(
        amountSats: gesture.sats!,
        comment: _donationMessages[gesture] ?? gesture.label,
      );
      emit(DonateSuccess(result.invoice));
    } on Exception catch (e, stack) {
      _log.warning('Preset zap failed', e, stack);
      emit(DonateFailure(showGift: showGift, userMessage: _userMessage(e)));
    }
  }

  Future<void> sendGift(int sats, String? comment) async {
    final showGift = switch (state) {
      DonateReady(showGift: final g) => g,
      DonateFailure(showGift: final g) => g,
      _ => false,
    };
    emit(DonateLoading(showGift: showGift));

    try {
      final result = await _zap.donate(
        amountSats: sats,
        comment: (comment != null && comment.isNotEmpty) ? comment : null,
      );
      emit(DonateSuccess(result.invoice));
    } on Exception catch (e, stack) {
      _log.warning('Gift zap failed', e, stack);
      emit(DonateFailure(showGift: showGift, userMessage: _userMessage(e)));
    }
  }

  String _userMessage(Object e) {
    if (e is SocketException || e is HttpException) {
      return 'No internet connection';
    }
    if (e is ZapException) return e.message;
    if (e is LnurlException) return e.message;
    return 'Something went wrong, try again';
  }
}
