import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';

class ZbShimmer extends StatefulWidget {
  const ZbShimmer({
    super.key,
    this.message = 'Zb is at it…',
    this.lineCount = 3,
  });

  final String message;
  final int lineCount;

  @override
  State<ZbShimmer> createState() => _ZbShimmerState();
}

class _ZbShimmerState extends State<ZbShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 16, color: colors.nostr),
            const SizedBox(width: 6),
            Text(
              widget.message,
              style: context.typography.caption.copyWith(color: colors.nostr),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var line = 0; line < widget.lineCount; line++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShimmerBar(
              controller: _controller,
              widthFactor: line.isEven ? 1.0 : 0.7,
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
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final shift = controller.value * 2 - 1;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(shift - 1, 0),
              end: Alignment(shift + 1, 0),
            ).createShader(bounds),
            child: child,
          );
        },
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
