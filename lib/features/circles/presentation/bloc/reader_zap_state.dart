part of 'reader_zap_cubit.dart';

sealed class ReaderZapState {
  const ReaderZapState();
}

class ReaderZapInitial extends ReaderZapState {
  const ReaderZapInitial();
}

class ReaderZapLoading extends ReaderZapState {
  final ZapGesture gesture;
  const ReaderZapLoading(this.gesture);
}

class ReaderZapSuccess extends ReaderZapState {
  final int amountSats;
  final String readerLabel;
  const ReaderZapSuccess({required this.amountSats, required this.readerLabel});
}

class ReaderZapFailure extends ReaderZapState {
  final String message;
  const ReaderZapFailure(this.message);
}
