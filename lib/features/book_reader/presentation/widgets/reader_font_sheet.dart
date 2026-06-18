import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_cubit.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reader_settings/reader_settings_state.dart';
import 'package:zapbook/theme/reading_style.dart';

class ReaderFontSheet extends StatelessWidget {
  const ReaderFontSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<ReaderSettingsCubit>();
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const ReaderFontSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return AppSheet(
      child: BlocBuilder<ReaderSettingsCubit, ReaderSettingsState>(
        builder: (context, state) {
          final cubit = context.read<ReaderSettingsCubit>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Reader appearance', style: typography.h3),
              ),
              _FontFamilySelector(
                currentFont: state.font,
                onFontSelected: cubit.setFont,
              ),
              const SizedBox(height: 24),
              Text(
                'Text size',
                style: typography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.slate,
                ),
              ),
              const SizedBox(height: 12),
              _ScaleSlider(
                value: state.textScale,
                min: 0.8,
                max: 2.0,
                onChanged: cubit.setTextScale,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _FontFamilySelector extends StatelessWidget {
  const _FontFamilySelector({
    required this.currentFont,
    required this.onFontSelected,
  });

  final ReaderFont currentFont;
  final ValueChanged<ReaderFont> onFontSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Row(
      children: ReaderFont.values.map((font) {
        final isSelected = font == currentFont;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: font == ReaderFont.values.last ? 0 : 8.0,
            ),
            child: Material(
              color: isSelected
                  ? colors.plum.withValues(alpha: 0.1)
                  : colors.paper2,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onFontSelected(font),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? colors.plum : colors.hairline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      font.displayName,
                      style: typography.body.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? colors.plum : colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final divisions = ((max - min) * 10).round();

    return Row(
      children: [
        _StepButton(
          icon: LucideIcons.minus,
          onTap: value > min
              ? () {
                  final next = (value - 0.1).clamp(min, max);
                  onChanged(next);
                }
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              activeTrackColor: colors.plum,
              inactiveTrackColor: colors.hairline2,
              thumbColor: colors.plum,
              overlayColor: colors.plum.withValues(alpha: 0.12),
              valueIndicatorColor: colors.plum,
              valueIndicatorTextStyle: typography.caption.copyWith(
                color: colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _StepButton(
          icon: LucideIcons.plus,
          onTap: value < max
              ? () {
                  final next = (value + 0.1).clamp(min, max);
                  onChanged(next);
                }
              : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? colors.paper3 : colors.paper2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? colors.hairline2 : colors.hairline,
          ),
        ),
        child: Icon(icon, size: 18, color: active ? colors.ink : colors.slate2),
      ),
    );
  }
}
