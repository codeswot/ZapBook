import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class DonateZapChip extends StatelessWidget {
  const DonateZapChip({
    super.key,
    required this.gesture,
    this.loading = false,
    this.onTap,
  });

  final ZapGesture gesture;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.paper2,
          borderRadius: AppRadii.br12,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: loading
                  ? Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.bitcoin,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        gesture.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Row(
              children: [
                Icon(LucideIcons.zap, size: 14, color: colors.bitcoin),
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
