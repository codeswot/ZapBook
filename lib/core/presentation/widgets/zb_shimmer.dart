import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';

class ZbShimmer extends StatefulWidget {
  const ZbShimmer({
    super.key,
    this.message = 'Optimizing page layout…',
    this.lineCount = 4,
  });

  final String message;
  final int lineCount;

  @override
  State<ZbShimmer> createState() => _ZbShimmerState();
}

class _ZbShimmerState extends State<ZbShimmer> with TickerProviderStateMixin {
  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.6 + (_pulseController.value * 0.4),
                child: Transform.scale(
                  scale: 0.95 + (_pulseController.value * 0.05),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.nostrTint.withValues(alpha: 0.4),
                    colors.bitcoinTint.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.nostrTint2.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _pulseController,
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 14,
                      color: colors.nostr,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colors.nostr, colors.bitcoin2],
                    ).createShader(bounds),
                    child: Text(
                      widget.message,
                      style: context.typography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (var line = 0; line < widget.lineCount; line++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShimmerBar(
              controller: _shimmerController,
              widthFactor: line == 0
                  ? 1.0
                  : line == 1
                  ? 0.85
                  : line == 2
                  ? 0.95
                  : 0.6,
              base: colors.mist,
              highlight: colors.paper4,
            ),
          ),
      ],
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.controller,
    required this.widthFactor,
    required this.base,
    required this.highlight,
  });

  final AnimationController controller;
  final double widthFactor;
  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final shift = controller.value * 2 - 1;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: [base, highlight, base],
                stops: const [0.3, 0.5, 0.7],
                begin: Alignment(shift - 1, -0.2),
                end: Alignment(shift + 1, 0.2),
              ).createShader(bounds),
              child: child,
            );
          },
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ),
    );
  }
}
