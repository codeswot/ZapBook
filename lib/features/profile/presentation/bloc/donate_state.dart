import 'package:equatable/equatable.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';

sealed class DonateState extends Equatable {
  const DonateState();

  @override
  List<Object?> get props => [];
}

class DonateReady extends DonateState {
  const DonateReady({this.showGift = false});
  final bool showGift;

  @override
  List<Object?> get props => [showGift];
}

class DonateLoading extends DonateState {
  const DonateLoading({required this.showGift, this.presetChip});
  final bool showGift;
  final ZapGesture? presetChip;

  bool get isGift => presetChip == null;

  @override
  List<Object?> get props => [showGift, presetChip];
}

class DonateSuccess extends DonateState {
  const DonateSuccess(this.invoice);
  final String invoice;

  @override
  List<Object?> get props => [invoice];
}

class DonateFailure extends DonateState {
  const DonateFailure({required this.showGift, required this.userMessage});
  final bool showGift;
  final String userMessage;

  @override
  List<Object?> get props => [showGift, userMessage];
}
