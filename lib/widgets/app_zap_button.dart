import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AppZapButton extends StatelessWidget {
  final ZapGesture gesture;
  final VoidCallback onTap;
  final bool compact;

  const AppZapButton({
    super.key,
    required this.gesture,
    required this.onTap,
    this.compact = false,
  });

  bool get hasAmount => gesture.sats != null;

  @override
  Widget build(BuildContext context) {
    return BouncingInteractiveWidget(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: context.colors.paper2,
          borderRadius: AppRadii.br12,
          border: Border.all(color: context.colors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(gesture.emoji, style: const TextStyle(fontSize: 18)),
            if (hasAmount && !compact) ...[
              const SizedBox(width: 6),
              Row(
                children: [
                  Icon(
                    LucideIcons.zap,
                    size: 12,
                    color: context.colors.bitcoin,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${gesture.sats}',
                    style: context.typography.bodyS.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.bitcoin,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
