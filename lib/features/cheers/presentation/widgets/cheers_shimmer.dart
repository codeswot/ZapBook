import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';

class CheersShimmer extends StatefulWidget {
  const CheersShimmer({super.key});

  @override
  State<CheersShimmer> createState() => _CheersShimmerState();
}

class _CheersShimmerState extends State<CheersShimmer>
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: CustomPaint(
            painter: _DottedBorderPainter(
              color: colors.hairline2,
              borderRadius: 20.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerElement(
                    controller: _controller,
                    width: 40,
                    height: 40,
                    borderRadius: AppRadii.br20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ShimmerElement(
                              controller: _controller,
                              width: 100,
                              height: 12,
                              borderRadius: AppRadii.br10,
                            ),
                            _ShimmerElement(
                              controller: _controller,
                              width: 40,
                              height: 10,
                              borderRadius: AppRadii.br10,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ShimmerElement(
                          controller: _controller,
                          width: 160,
                          height: 14,
                          borderRadius: AppRadii.br10,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerElement(
                          controller: _controller,
                          width: 120,
                          height: 10,
                          borderRadius: AppRadii.br10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
