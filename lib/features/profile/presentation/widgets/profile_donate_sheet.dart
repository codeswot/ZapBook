import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_state.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_donate_gift_chip.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_donate_gift_form.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_donate_zap_chip.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ProfileDonateSheet extends StatelessWidget {
  const ProfileDonateSheet({super.key});

  @override
  Widget build(BuildContext context) => const _Body();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => DonateCubit(getIt<ZapService>()),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _messageController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  void _onStateChanged(BuildContext context, DonateState state) {
    if (state is DonateSuccess) {
      _pay(context, state.invoice);
    } else if (state is DonateFailure) {
      context.toast.showError(state.userMessage, rootNavigator: true);
    }
  }

  Future<void> _pay(BuildContext context, String pr) async {
    final uri = Uri.tryParse('lightning:$pr');
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;

    if (!opened) {
      await Clipboard.setData(ClipboardData(text: pr));
      if (!context.mounted) return;
      context.toast.showInfo(
        'Invoice copied — paste in any Lightning wallet',
        rootNavigator: true,
      );
    }
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DonateCubit, DonateState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final colors = context.colors;
        final typography = context.typography;
        final cubit = context.read<DonateCubit>();
        final showGift = switch (state) {
          DonateReady(showGift: final g) => g,
          DonateLoading(showGift: final g) => g,
          DonateFailure(showGift: final g) => g,
          _ => false,
        };
        final sending = state is DonateLoading;
        final sendingChip = state is DonateLoading ? state.presetChip : null;

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Clipboard.setData(ClipboardData(text: cubit.recipient));
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
                          cubit.recipient,
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
                const SizedBox(height: 22),
                Text(
                  'Quick zap',
                  style: typography.eyebrow.copyWith(color: colors.slate2),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,

                  children: [
                    DonateZapChip(
                      gesture: ZapGesture.thumbsUp,
                      loading: sendingChip == ZapGesture.thumbsUp,
                      onTap: sending
                          ? null
                          : () => cubit.sendPreset(ZapGesture.thumbsUp),
                    ),
                    DonateZapChip(
                      gesture: ZapGesture.clap,
                      loading: sendingChip == ZapGesture.clap,
                      onTap: sending
                          ? null
                          : () => cubit.sendPreset(ZapGesture.clap),
                    ),
                    DonateZapChip(
                      gesture: ZapGesture.fire,
                      loading: sendingChip == ZapGesture.fire,
                      onTap: sending
                          ? null
                          : () => cubit.sendPreset(ZapGesture.fire),
                    ),
                    DonateGiftChip(
                      active: showGift,
                      onTap: sending ? null : cubit.toggleGift,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: showGift
                      ? DonateGiftForm(
                          amountController: _amountController,
                          messageController: _messageController,
                          amountFocus: _amountFocus,
                          sending: sending && sendingChip == null,
                          valid:
                              _amountController.text.isNotEmpty &&
                              int.tryParse(_amountController.text) != null,
                          onSend: () => cubit.sendGift(
                            int.parse(_amountController.text),
                            _messageController.text.trim(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
