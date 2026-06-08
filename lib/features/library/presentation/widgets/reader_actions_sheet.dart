import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/library/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/circle_members_state.dart'
    show MemberEntry;
import 'package:zapbook/features/library/presentation/widgets/circle_confirm_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/reader_zap_sheet.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ReaderActionsSheet extends StatelessWidget {
  const ReaderActionsSheet({
    super.key,
    required this.cubit,
    required this.entry,
    required this.bookId,
    required this.canRemove,
  });

  final CircleDetailCubit cubit;
  final MemberEntry entry;
  final String bookId;
  final bool canRemove;

  static Future<void> show(
    BuildContext context, {
    required CircleDetailCubit cubit,
    required MemberEntry entry,
    required String bookId,
    required bool canRemove,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ReaderActionsSheet(
        cubit: cubit,
        entry: entry,
        bookId: bookId,
        canRemove: canRemove,
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    context.pop();
    final ok = await CircleConfirmSheet.show(
      context,
      title: 'Remove ${entry.contact.label}?',
      message:
          'They’ll lose access to this circle and the shared book on their '
          'device. You can add them back later.',
      action: 'Remove reader',
    );
    if (ok) await cubit.removeMember(bookId, entry.npub);
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
              AppProfileAvatar(url: entry.contact.picture ?? '', size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.contact.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.h3.copyWith(color: colors.ink),
                    ),
                    Text(
                      entry.contact.shortNpub,
                      style: typography.bodyS.copyWith(color: colors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionRow(
            icon: LucideIcons.zap,
            label: 'Zap reader',
            tone: colors.bitcoin,
            onTap: () {
              context.pop();
              ReaderZapSheet.show(context, entry.contact);
            },
          ),
          if (canRemove) ...[
            const SizedBox(height: 10),
            _ActionRow(
              icon: LucideIcons.userMinus,
              label: 'Remove from circle',
              tone: colors.tomato,
              onTap: () => _remove(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = tone ?? colors.ink;
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.paper3,
          borderRadius: AppRadii.br12,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyL.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
