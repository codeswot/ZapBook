import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_button.dart';

class DonateGiftForm extends StatelessWidget {
  const DonateGiftForm({
    super.key,
    required this.amountController,
    required this.messageController,
    required this.amountFocus,
    required this.sending,
    required this.valid,
    required this.onSend,
  });

  final TextEditingController amountController;
  final TextEditingController messageController;
  final FocusNode amountFocus;
  final bool sending;
  final bool valid;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

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
                  controller: amountController,
                  focusNode: amountFocus,
                  keyboardType: TextInputType.number,
                  enabled: !sending,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Amount (sats)',
                    prefixIcon: Icon(LucideIcons.zap, size: 16, color: colors.bitcoin),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: typography.body.copyWith(fontWeight: FontWeight.w600, color: colors.ink),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: messageController,
                  enabled: !sending,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  style: typography.body.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: sending ? 'Resolving…' : 'Send gift',
            fullWidth: true,
            icon: LucideIcons.gift,
            isLoading: sending,
            onTap: (valid && !sending) ? onSend : null,
          ),
        ],
      ),
    );
  }
}
