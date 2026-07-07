part of 'reader_init_cubit.dart';

sealed class ReaderInitState extends Equatable {
  const ReaderInitState();

  @override
  List<Object?> get props => [];
}

class ReaderInitInitial extends ReaderInitState {
  const ReaderInitInitial();
}

class ReaderInitLoading extends ReaderInitState {
  const ReaderInitLoading();
}

class ReaderInitLoaded extends ReaderInitState {
  final ZbfBookHandle handle;
  const ReaderInitLoaded(this.handle);

  @override
  List<Object?> get props => [handle];
}

class ReaderInitError extends ReaderInitState {
  final String message;
  const ReaderInitError(this.message);

  @override
  List<Object?> get props => [message];
}
