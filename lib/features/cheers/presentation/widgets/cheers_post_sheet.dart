import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';

class CheersPostSheet extends StatefulWidget {
  const CheersPostSheet({
    super.key,
    required this.activity,
    required this.cubit,
  });

  final CheersActivity activity;
  final CheersCubit cubit;

  static Future<void> show(
    BuildContext context, {
    required CheersActivity activity,
    required CheersCubit cubit,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CheersPostSheet(activity: activity, cubit: cubit),
      ),
    );
  }

  @override
  State<CheersPostSheet> createState() => _CheersPostSheetState();
}

class _CheersPostSheetState extends State<CheersPostSheet> {
  late final TextEditingController _controller;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.cubit.noteTextFor(widget.activity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_posting) return;
    setState(() => _posting = true);
    await widget.cubit.postActivityAsNote(widget.activity, _controller.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Post as note',
              style: typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this on Nostr as a public note. Edit it or post as is.',
              style: typography.bodyS.copyWith(color: colors.slate),
            ),
            const SizedBox(height: 18),
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.paper2,
                borderRadius: AppRadii.br16,
                border: Border.all(color: colors.hairline2),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: typography.body.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  color: colors.ink,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Post',
              variant: AppButtonVariant.primary,
              fullWidth: true,
              isLoading: _posting,
              onTap: _post,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
