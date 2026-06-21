import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/widgets/zap_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_tile.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileDonateTile extends StatelessWidget {
  const ProfileDonateTile({super.key});

  void _showDonateSheet(BuildContext context, String recipient) {
    final colors = context.colors;
    final typography = context.typography;
    final cubit = context.read<ProfileCubit>();

    ZapSheet.show(
      context: context,
      header: StatefulBuilder(
        builder: (context, setLocal) {
          final percentValue = cubit.supportPercent;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Support ZapBook',
                style: typography.displayM.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 8),
              BouncingInteractiveWidget(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: recipient));
                  context.toast.showInfo(
                    'Lightning address copied',
                    rootNavigator: true,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        recipient,
                        style: typography.mono.copyWith(
                          color: colors.slate,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.copy, size: 13, color: colors.slate2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (cubit.isNwcConnected) ...[
                Container(height: 1, color: colors.hairline2),
                const SizedBox(height: 16),
                Text(
                  'Auto donation zaps',
                  style: typography.caption.copyWith(
                    color: colors.coral,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StepButton(
                      icon: LucideIcons.minus,
                      onTap: percentValue > 0
                          ? () {
                              final options = cubit.supportPercentOptions;
                              final idx = options.indexOf(percentValue);
                              if (idx > 0) {
                                cubit.setSupportPercent(options[idx - 1]);
                                setLocal(() {});
                              }
                            }
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 20,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 0,
                            pressedElevation: 0,
                          ),
                          activeTrackColor: colors.bitcoin,
                          inactiveTrackColor: colors.bitcoin.withValues(alpha: 0.24),
                          thumbColor: colors.paper,
                          overlayColor: colors.bitcoin.withValues(alpha: 0.12),
                          valueIndicatorColor: colors.bitcoin,
                          valueIndicatorTextStyle: typography.caption.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Slider(
                          value: cubit.supportPercentOptions
                              .indexOf(percentValue)
                              .toDouble(),
                          min: 0,
                          max: (cubit.supportPercentOptions.length - 1)
                              .toDouble(),
                          divisions: cubit.supportPercentOptions.length - 1,
                          label: percentValue == 0 ? 'Off' : '$percentValue%',
                          onChanged: (v) {
                            cubit.setSupportPercent(
                              cubit.supportPercentOptions[v.round()],
                            );
                            setLocal(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StepButton(
                      icon: LucideIcons.plus,
                      onTap: () {
                        final options = cubit.supportPercentOptions;
                        final idx = options.indexOf(percentValue);
                        if (idx < options.length - 1) {
                          cubit.setSupportPercent(options[idx + 1]);
                          setLocal(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.slate2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        percentValue == 0
                            ? 'Add a % on top of each zap you send. The extra supports ZapBook. You can opt out anytime.'
                            : 'Each zap you send adds $percentValue% on top to support ZapBook. E.g. 100 sats → friend gets 100, ZapBook gets $percentValue.',
                        style: typography.bodyS.copyWith(
                          color: colors.slate,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),

      onZapSelected: (gesture, amount, message) =>
          _handleDonate(context, gesture, amount, message),
    );
  }

  static const _donationMessages = {
    ZapGesture.thumbsUp: 'Well done',
    ZapGesture.clap: 'ZapBook is awesome',
    ZapGesture.fire: 'Keep building ZapBook',
    ZapGesture.rocket: 'ZapBook To the moon!',
    ZapGesture.trophy: 'Absolutely legendary!',
  };

  Future<void> _handleDonate(
    BuildContext context,
    ZapGesture gesture,
    int amount,
    String? comment,
  ) async {
    final messenger = context.toast;

    try {
      final zap = getIt<ZapService>();
      final result = await zap.donate(
        amountSats: amount,
        comment: comment ?? _donationMessages[gesture] ?? gesture.label,
      );
      final launched = await zap.payWithFallback(result.invoice);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: result.invoice));
        messenger.showInfo('Invoice copied to clipboard');
      } else {
        messenger.showSuccess('Zapping $amount sats to support ZapBook');
      }
    } catch (_) {
      messenger.showError('Could not send donation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipient = context.read<ProfileCubit>().donationRecipient;
    final colors = context.colors;
    return ProfileTile(
      icon: LucideIcons.zap,
      iconColor: colors.bitcoin,
      title: 'Support ZapBook',
      subtitle: recipient,
      onTap: () => _showDonateSheet(context, recipient),
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
