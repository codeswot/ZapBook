import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/theme/app_theme.dart';

import 'package:zapbook/core/theme/theme_cubit.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/reader_settings/reader_settings_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_progress.dart';

class ReaderFooter extends StatelessWidget {
  const ReaderFooter({
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    super.key,
  });

  final double progress;
  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final themeCubit = context.read<ThemeCubit>();

    return Container(
      decoration: BoxDecoration(
        color: colors.paper.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _FooterIconButton(
                    icon: Icons.text_fields_rounded,
                    tooltip: 'Reading font',
                    onTap: context.read<ReaderSettingsCubit>().cycleFont,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ReaderProgress(value: progress),
                    ),
                  ),
                  BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, mode) {
                      return _FooterIconButton(
                        icon: mode == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        tooltip: 'Theme',
                        onTap: themeCubit.toggle,
                      );
                    },
                  ),
                ],
              ),
              Text(
                '${currentPage + 1} / $totalPages',
                style: typography.caption.copyWith(
                  color: colors.slate2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20, color: colors.ink),
    );
  }
}
