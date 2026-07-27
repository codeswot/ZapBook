import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/widgets/reader_zap_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_loading_list.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_row.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';

class HighlightZapPickerSheet extends StatefulWidget {
  const HighlightZapPickerSheet({
    super.key,
    required this.groupId,
    required this.bookTitle,
  });

  final String groupId;
  final String bookTitle;

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required String bookTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) =>
          HighlightZapPickerSheet(groupId: groupId, bookTitle: bookTitle),
    );
  }

  @override
  State<HighlightZapPickerSheet> createState() =>
      _HighlightZapPickerSheetState();
}

class _HighlightZapPickerSheetState extends State<HighlightZapPickerSheet> {
  late final Future<List<Contact>> _members;

  @override
  void initState() {
    super.initState();
    _members = getIt<GetCircleMembersUseCase>().call(widget.groupId);
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
          Text(
            'Zap this quote',
            style: typography.displayM.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a circle member to send sats to.',
            style: typography.body.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Contact>>(
            future: _members,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const AppLoadingList(itemCount: 4);
              }
              final members = snapshot.data!;
              if (members.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No circle members to zap yet.',
                    style: typography.body.copyWith(color: colors.slate),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: [
                  for (final member in members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppRow(
                        leading: AppProfileAvatar(
                          url: member.picture ?? '',
                          size: 40,
                        ),
                        title: member.label,
                        subtitle: member.shortNpub,
                        trailing: Icon(
                          LucideIcons.zap,
                          size: 20,
                          color: colors.bitcoin,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          ReaderZapSheet.show(
                            context,
                            reader: member,
                            circleId: widget.groupId,
                            circleBookTitle: widget.bookTitle,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
