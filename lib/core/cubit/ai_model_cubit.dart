import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/services/ai_service.dart';

@injectable
class AiModelCubit extends Cubit<AiModelState> {
  final AiService _aiService;
  StreamSubscription<AiModelState>? _subscription;

  AiModelCubit(this._aiService) : super(_aiService.currentState) {
    _subscription = _aiService.aiState.listen((state) {
      emit(state);
    });
  }

  void startDownload(String url, String hash) => _aiService.startDownload(url, hash);
  void pauseDownload() => _aiService.pauseDownload();
  void resumeDownload() => _aiService.resumeDownload();
  void cancelDownload() => _aiService.cancelDownload();
  void skipSetup() => _aiService.skipSetup();
  void reset() => _aiService.reset();
  void dismissBanner() => _aiService.dismissBanner();

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
