import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/theme/app_theme.dart';

class FriendListItem extends StatelessWidget {
  final Contact friend;
  final String? busyNpub;
  final VoidCallback onRemove;

  const FriendListItem({
    super.key,
    required this.friend,
    required this.busyNpub,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AppProfileAvatar(url: friend.picture ?? '', size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friend.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.bodyL.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: friend.npub));
                    context.toast.showInfo('npub copied', rootNavigator: true);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        friend.shortNpub,
                        style: typography.bodyS.copyWith(color: colors.slate),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.copy, size: 12, color: colors.slate2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (busyNpub == friend.npub)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            BouncingInteractiveWidget(
              onTap: onRemove,
              child: Icon(
                LucideIcons.userMinus,
                size: 20,
                color: colors.tomato,
              ),
            ),
        ],
      ),
    );
  }
}
