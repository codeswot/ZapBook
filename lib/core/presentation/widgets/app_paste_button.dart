import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/presentation/bloc/clipboard/clipboard_cubit.dart';
import 'package:zapbook/core/presentation/widgets/app_square_icon_button.dart';

class AppPasteButton extends StatelessWidget {
  const AppPasteButton({super.key, required this.onPaste});

  final ValueChanged<String> onPaste;

  @override
  Widget build(BuildContext context) {
    return AppSquareIconButton(
      icon: LucideIcons.clipboard,
      onTap: () async {
        final text = await context.read<ClipboardCubit>().paste();
        if (text != null && text.isNotEmpty) {
          onPaste(text.trim());
        }
      },
    );
  }
}
