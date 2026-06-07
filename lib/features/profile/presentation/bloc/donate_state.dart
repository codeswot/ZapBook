import 'package:zapbook/core/domain/zap_gesture.dart';

sealed class DonateState {
  const DonateState();
}

class DonateReady extends DonateState {
  const DonateReady({this.showGift = false});
  final bool showGift;
}

class DonateLoading extends DonateState {
  const DonateLoading({required this.showGift, this.presetChip});
  final bool showGift;
  final ZapGesture? presetChip;

  bool get isGift => presetChip == null;
}

class DonateSuccess extends DonateState {
  const DonateSuccess(this.invoice);
  final String invoice;
}

class DonateFailure extends DonateState {
  const DonateFailure({required this.showGift, required this.userMessage});
  final bool showGift;
  final String userMessage;
}
