import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class ProfileShareSheet extends StatelessWidget {
  const ProfileShareSheet({
    super.key,
    required this.profile,
    required this.onCopy,
  });

  final UserProfile profile;
  final Future<void> Function(String value) onCopy;

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    required Future<void> Function(String value) onCopy,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ProfileShareSheet(profile: profile, onCopy: onCopy),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await onCopy(profile.npub);
    if (context.mounted) {
      context.toast.showSuccess('npub copied', rootNavigator: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Profile',
              style: typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 20),
            AppProfileAvatar(url: profile.picture, size: 96),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              style: typography.h1.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: colors.ink,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final edge = constraints.maxWidth;
                return Container(
                  width: edge,
                  height: edge,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.white,
                    borderRadius: AppRadii.br24,
                    border: Border.all(color: colors.hairline),
                  ),
                  child: QrImageView(
                    data: profile.npub,
                    backgroundColor: colors.white,
                    gapless: false,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: colors.nostr,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: colors.black,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.npub.toNpubShort(),
                  style: typography.mono.copyWith(color: colors.slate),
                ),
                const SizedBox(width: 8),
                BouncingInteractiveWidget(
                  onTap: () => _copy(context),
                  child: Icon(
                    LucideIcons.copy,
                    size: 16,
                    color: colors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
