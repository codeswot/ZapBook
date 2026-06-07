import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/features/profile/domain/usecases/send_donation.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ProfileDonateSheet extends StatefulWidget {
  const ProfileDonateSheet({super.key});

  static const _recipient = 'zapbook@blink.sv';

  @override
  State<ProfileDonateSheet> createState() => _ProfileDonateSheetState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileDonateSheet(),
    );
  }
}

class _ProfileDonateSheetState extends State<ProfileDonateSheet> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  final _amountFocus = FocusNode();
  ZapGesture? _sendingChip;
  bool _giftSending = false;
  bool _showGift = false;
  String? _error;

  bool get _anySending => _sendingChip != null || _giftSending;

  bool get _giftValid =>
      _amountController.text.isNotEmpty &&
      int.tryParse(_amountController.text) != null;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _toggleGift() {
    setState(() {
      _showGift = !_showGift;
      _error = null;
    });
    if (_showGift) {
      _amountFocus.requestFocus();
    }
  }

  Future<void> _sendPreset(ZapGesture gesture) async {
    setState(() {
      _sendingChip = gesture;
      _error = null;
    });

    try {
      final donation = getIt<SendDonation>();
      final invoice = await donation(
        amountSats: gesture.sats!,
        comment: gesture.label,
      );

      final uri = Uri.tryParse('lightning:${invoice.pr}');
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        setState(() => _sendingChip = null);
        Navigator.of(context).pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _sendingChip = null;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _sendGift() async {
    final sats = int.tryParse(_amountController.text);
    if (sats == null || sats <= 0) return;

    setState(() {
      _giftSending = true;
      _error = null;
    });

    try {
      final comment = _messageController.text.trim();
      final donation = getIt<SendDonation>();
      final invoice = await donation(
        amountSats: sats,
        comment: comment.isNotEmpty ? comment : null,
      );

      final uri = Uri.tryParse('lightning:${invoice.pr}');
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        setState(() => _giftSending = false);
        Navigator.of(context).pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _giftSending = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

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
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  const ClipboardData(text: ProfileDonateSheet._recipient),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lightning address copied')),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      ProfileDonateSheet._recipient,
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
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _ZapChip(
                  gesture: ZapGesture.thumbsUp,
                  loading: _sendingChip == ZapGesture.thumbsUp,
                  onTap: _anySending
                      ? null
                      : () => _sendPreset(ZapGesture.thumbsUp),
                ),
                _ZapChip(
                  gesture: ZapGesture.clap,
                  loading: _sendingChip == ZapGesture.clap,
                  onTap: _anySending
                      ? null
                      : () => _sendPreset(ZapGesture.clap),
                ),
                _ZapChip(
                  gesture: ZapGesture.fire,
                  loading: _sendingChip == ZapGesture.fire,
                  onTap: _anySending
                      ? null
                      : () => _sendPreset(ZapGesture.fire),
                ),
                _GiftChip(
                  active: _showGift,
                  onTap: _anySending ? null : _toggleGift,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _showGift
                  ? _giftForm(colors, typography)
                  : const SizedBox.shrink(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: typography.bodyS.copyWith(color: colors.tomato),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _giftForm(dynamic colors, dynamic typography) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  keyboardType: TextInputType.number,
                  enabled: !_giftSending,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Amount (sats)',
                    prefixIcon: Icon(
                      LucideIcons.zap,
                      size: 16,
                      color: colors.bitcoin,
                    ),
                    filled: true,
                    fillColor: colors.paper2,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.br10,
                      borderSide: BorderSide(color: colors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.br10,
                      borderSide: BorderSide(color: colors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.br10,
                      borderSide: BorderSide(color: colors.bitcoin),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _messageController,
                  enabled: !_giftSending,
                  decoration: InputDecoration(
                    hintText: 'Optional message',
                    filled: true,
                    fillColor: colors.paper2,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.br10,
                      borderSide: BorderSide(color: colors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.br10,
                      borderSide: BorderSide(color: colors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.br10,
                      borderSide: BorderSide(color: colors.bitcoin),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: typography.body.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: _giftSending ? 'Resolving…' : 'Send gift',
            fullWidth: true,
            icon: LucideIcons.gift,
            isLoading: _giftSending,
            onTap: (_giftValid && !_anySending) ? _sendGift : null,
          ),
        ],
      ),
    );
  }
}

class _ZapChip extends StatelessWidget {
  const _ZapChip({required this.gesture, this.loading = false, this.onTap});

  final ZapGesture gesture;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.paper2,
          borderRadius: AppRadii.br12,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.bitcoin,
                ),
              )
            else
              Text(gesture.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Row(
              children: [
                Icon(LucideIcons.zap, size: 12, color: colors.bitcoin),
                const SizedBox(width: 2),
                Text(
                  '${gesture.sats}',
                  style: context.typography.bodyS.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.bitcoin,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftChip extends StatelessWidget {
  const _GiftChip({required this.active, this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? colors.bitcoinTint : colors.paper2,
          borderRadius: AppRadii.br12,
          border: Border.all(
            color: active
                ? colors.bitcoin.withValues(alpha: 0.3)
                : colors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              'Gift',
              style: context.typography.bodyS.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
