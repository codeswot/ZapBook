import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:zapbook/core/domain/usecases/clipboard_usecases.dart';

class ClipboardState {
  const ClipboardState();
}

@injectable
class ClipboardCubit extends Cubit<ClipboardState> {
  ClipboardCubit(this._copyText, this._pasteText)
    : super(const ClipboardState());

  final CopyTextUseCase _copyText;
  final PasteTextUseCase _pasteText;

  Future<void> copy(String text) async {
    await _copyText(text);
  }

  Future<String?> paste() async {
    return await _pasteText();
  }
}
