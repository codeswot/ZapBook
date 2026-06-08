import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AppPasteButton extends StatelessWidget {
  const AppPasteButton({super.key, required this.onPaste});

  final ValueChanged<String> onPaste;

  @override
  Widget build(BuildContext context) {
    return BouncingInteractiveWidget(
      onTap: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.isNotEmpty) {
          onPaste(text.trim());
        }
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: context.colors.paper2,
          borderRadius: AppRadii.br10,
          border: Border.all(color: context.colors.hairline),
        ),
        child: Icon(LucideIcons.clipboard, color: context.colors.slate),
      ),
    );
  }
}
