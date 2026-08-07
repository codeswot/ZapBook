import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_qr_code.dart';
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Profile',
                  textAlign: TextAlign.start,
                  style: typography.displayM.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let friends scan this QR code to easily add you',
                  style: typography.body.copyWith(color: colors.slate),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 20),
              ],
            ),
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
            AppQrCode(data: profile.npub),
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
                  child: Icon(LucideIcons.copy, size: 16, color: colors.slate),
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
