import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

class AppBlocObserver extends BlocObserver {
  final _logger = Logger('AppBlocObserver');

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.fine('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.fine('onEvent -- ${bloc.runtimeType}, ${event.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.fine(
      'onChange -- ${bloc.runtimeType}, '
      '${change.currentState.runtimeType} -> ${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.fine(
      'onTransition -- ${bloc.runtimeType}, '
      '${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.severe('onError -- ${bloc.runtimeType}, $error', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.fine('onClose -- ${bloc.runtimeType}');
  }
}
