import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class CircleDetailBottomBar extends StatelessWidget {
  const CircleDetailBottomBar({
    super.key,
    required this.isOwner,
    required this.processing,
    required this.onDelete,
    required this.onLeave,
  });

  final bool isOwner;
  final bool processing;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paper2,
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: AppButton(
            label: isOwner ? 'Delete circle' : 'Leave circle',
            icon: isOwner ? LucideIcons.trash2 : LucideIcons.logOut,
            variant: AppButtonVariant.danger,
            fullWidth: true,
            isLoading: processing,
            onTap: isOwner ? onDelete : onLeave,
          ),
        ),
      ),
    );
  }
}
