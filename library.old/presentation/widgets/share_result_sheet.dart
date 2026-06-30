import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_row.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class ShareResultSheet extends StatelessWidget {
  const ShareResultSheet({
    super.key,
    required this.skips,
    required this.friends,
  });

  final List<ShareSkip> skips;
  final List<Contact> friends;

  String _labelFor(String npub) {
    for (final c in friends) {
      if (c.npub == npub) return c.label;
    }
    return npub.length <= 16
        ? npub
        : '${npub.substring(0, 12)}…${npub.substring(npub.length - 4)}';
  }

  static Future<void> show(
    BuildContext context,
    List<ShareSkip> skips,
    List<Contact> friends,
  ) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ShareResultSheet(skips: skips, friends: friends),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.triangleAlert, size: 20, color: colors.tomato),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skips.length == 1
                      ? 'Couldn\'t share with 1 person'
                      : 'Couldn\'t share with ${skips.length} people',
                  style: typography.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'These people need ZapBook to receive shared books. Invite them to install ZapBook or update their key package.',
            style: typography.body.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 16),
          ...skips.map(
            (skip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppRow(
                leading: AppProfileAvatar(
                  url: _pictureFor(skip.npub) ?? '',
                  size: 40,
                ),
                title: _labelFor(skip.npub),
                subtitle: skip.description(),
                trailing: Icon(LucideIcons.x, size: 20, color: colors.tomato),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Done',
            variant: AppButtonVariant.ghost,
            fullWidth: true,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }

  String? _pictureFor(String npub) {
    for (final c in friends) {
      if (c.npub == npub) return c.picture;
    }
    return null;
  }
}
