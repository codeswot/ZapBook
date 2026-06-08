import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ZapSheet extends StatefulWidget {
  const ZapSheet({
    super.key,
    required this.header,
    required this.onZapSelected,
  });

  final Widget header;
  final void Function(ZapGesture gesture, int amount, String? message)
  onZapSelected;

  static Future<void> show({
    required BuildContext context,
    required Widget header,
    required void Function(ZapGesture gesture, int amount, String? message)
    onZapSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => ZapSheet(header: header, onZapSelected: onZapSelected),
    );
  }

  @override
  State<ZapSheet> createState() => _ZapSheetState();
}

class _ZapSheetState extends State<ZapSheet> {
  bool _showGift = false;
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final reactions = [
      ZapGesture.thumbsUp,
      ZapGesture.clap,
      ZapGesture.fire,
      ZapGesture.rocket,
      ZapGesture.trophy,
    ];

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.header,
            const SizedBox(height: 20),
            Text(
              'Tap a reaction — the sats send instantly',
              style: typography.bodyS.copyWith(
                color: colors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: reactions.map((gesture) {
                final formattedSats = gesture.sats == 1000
                    ? '1k'
                    : gesture.sats == 2100
                    ? '2.1k'
                    : gesture.sats == 5000
                    ? '5k'
                    : '${gesture.sats}';

                return Expanded(
                  child: BouncingInteractiveWidget(
                    onTap: () {
                      context.pop();
                      widget.onZapSelected(gesture, gesture.sats ?? 21, null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: colors.paper3,
                        borderRadius: AppRadii.br12,
                        border: Border.all(color: colors.hairline2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            gesture.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.zap,
                                size: 10,
                                color: colors.bitcoin,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                formattedSats,
                                style: typography.caption.copyWith(
                                  color: colors.bitcoin,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            BouncingInteractiveWidget(
              onTap: () {
                setState(() {
                  _showGift = !_showGift;
                });
              },
              child: CustomPaint(
                painter: _DottedBorderPainter(
                  color: colors.nostr.withValues(alpha: 0.2),
                  borderRadius: 16.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.nostr.withValues(alpha: 0.2),
                          border: Border.all(color: colors.nostr),
                          borderRadius: AppRadii.br10,
                        ),
                        child: Center(
                          child: Text(
                            '🎁',
                            textAlign: TextAlign.center,
                            style: typography.bodyL.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gift wrap',
                              style: typography.bodyL.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose any amount + add a note',
                              style: typography.caption.copyWith(
                                color: colors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showGift
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 20,
                        color: colors.slate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _showGift
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            label: 'Enter custom amount',
                            hintText: '200',
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            controller: _messageController,
                            label: 'Leave a note',
                            hintText: 'Great things are happening',
                          ),
                          const SizedBox(height: 16),
                          BouncingInteractiveWidget(
                            onTap: () {
                              final amt = int.tryParse(_amountController.text);
                              if (amt != null && amt > 0) {
                                context.pop();
                                widget.onZapSelected(
                                  ZapGesture.gift,
                                  amt,
                                  _messageController.text.trim(),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: colors.bitcoin,
                                borderRadius: AppRadii.br12,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Send Zap',
                                style: typography.button.copyWith(
                                  color: colors.bitcoinDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? 4.0 : 4.0;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
