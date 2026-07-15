import 'package:injectable/injectable.dart';
import 'package:zapbook/core/data/infrastructure/clipboard_service.dart';

@injectable
class CopyTextUseCase {
  const CopyTextUseCase(this._clipboardService);

  final ClipboardService _clipboardService;

  Future<void> call(String text) => _clipboardService.copy(text);
}

@injectable
class PasteTextUseCase {
  const PasteTextUseCase(this._clipboardService);

  final ClipboardService _clipboardService;

  Future<String?> call() => _clipboardService.paste();
}
