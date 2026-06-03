import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class LibraryShimmer extends StatefulWidget {
  const LibraryShimmer({super.key});

  @override
  State<LibraryShimmer> createState() => _LibraryShimmerState();
}

class _LibraryShimmerState extends State<LibraryShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: CustomPaint(
              painter: _DottedBorderPainter(
                color: colors.hairline2,
                borderRadius: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _ShimmerElement(
                      controller: _controller,
                      width: 56,
                      height: 77,
                      borderRadius: AppRadii.br12,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ShimmerElement(
                            controller: _controller,
                            width: 110,
                            height: 12,
                            borderRadius: AppRadii.br10,
                          ),
                          const SizedBox(height: 8),
                          _ShimmerElement(
                            controller: _controller,
                            width: 180,
                            height: 18,
                            borderRadius: AppRadii.br10,
                          ),
                          const SizedBox(height: 6),
                          _ShimmerElement(
                            controller: _controller,
                            width: 120,
                            height: 14,
                            borderRadius: AppRadii.br10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ShimmerElement(
                      controller: _controller,
                      width: 40,
                      height: 40,
                      borderRadius: AppRadii.br20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: SliverToBoxAdapter(
            child: Text(
              'All Books',
              style: typography.eyebrow.copyWith(
                color: colors.slate,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.727,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = width / 0.727;
                    return CustomPaint(
                      painter: _DottedBorderPainter(
                        color: colors.hairline2,
                        borderRadius: 12.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Spacer(),
                            _ShimmerElement(
                              controller: _controller,
                              width: width - 16,
                              height: 12,
                              borderRadius: AppRadii.br10,
                            ),
                            const SizedBox(height: 6),
                            _ShimmerElement(
                              controller: _controller,
                              width: (width - 16) * 0.7,
                              height: 9,
                              borderRadius: AppRadii.br10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerElement extends StatelessWidget {
  const _ShimmerElement({
    required this.controller,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final AnimationController controller;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shift = controller.value * 2 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [colors.mist, colors.paper4, colors.mist],
            stops: const [0.3, 0.5, 0.7],
            begin: Alignment(shift - 1, -0.2),
            end: Alignment(shift + 1, 0.2),
          ).createShader(bounds),
          child: child,
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.mist,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashPattern = const [4, 4],
    this.borderRadius = 12.0,
  });

  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
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
        final len = dashPattern[draw ? 0 : 1 % dashPattern.length];
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
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
