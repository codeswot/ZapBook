import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/zbf/zbf.dart';

class CirclePromptSheet extends StatelessWidget {
  final BookManifest? manifest;
  final VoidCallback onCreateCircle;
  final VoidCallback onJustRead;

  const CirclePromptSheet({
    super.key,
    required this.manifest,
    required this.onCreateCircle,
    required this.onJustRead,
  });

  static Future<void> show(
    BuildContext context, {
    required BookManifest? manifest,
    required VoidCallback onCreateCircle,
    required VoidCallback onJustRead,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CirclePromptSheet(
        manifest: manifest,
        onCreateCircle: onCreateCircle,
        onJustRead: onJustRead,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: context.colors.plumTint,
              borderRadius: AppRadii.br24,
              border: Border.all(color: context.colors.plumTint2),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.users,
              color: context.colors.plum,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Nice — first book added",
            style: context.typography.bodyS.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.plum,
              letterSpacing: 0.12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Start a reading circle with ${manifest?.title ?? 'your new book'}?",
            style: context.typography.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            "Invite up to 100 people to read it together. Anyone in the circle can zap anyone who hits a milestone.",
            style: context.typography.body.copyWith(
              color: context.colors.slate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          AppButton(
            label: "Yes, create a circle",
            variant: AppButtonVariant.purple,
            fullWidth: true,
            icon: LucideIcons.users,
            onTap: onCreateCircle,
          ),
          const SizedBox(height: 11),
          AppButton(
            label: "Not now — just read",
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: onJustRead,
          ),
        ],
      ),
    );
  }
}
