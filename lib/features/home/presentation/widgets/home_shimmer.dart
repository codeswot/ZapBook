import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';

class HomeShimmer extends StatefulWidget {
  const HomeShimmer({super.key});

  @override
  State<HomeShimmer> createState() => _HomeShimmerState();
}

class _HomeShimmerState extends State<HomeShimmer>
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

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomPaint(
            painter: _DottedBorderPainter(
              color: colors.hairline2,
              borderRadius: 20.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerElement(
                        controller: _controller,
                        width: 64,
                        height: 84,
                        borderRadius: AppRadii.br12,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerElement(
                              controller: _controller,
                              width: 80,
                              height: 12,
                              borderRadius: AppRadii.br10,
                            ),
                            const SizedBox(height: 8),
                            _ShimmerElement(
                              controller: _controller,
                              width: 160,
                              height: 18,
                              borderRadius: AppRadii.br10,
                            ),
                            const SizedBox(height: 8),
                            _ShimmerElement(
                              controller: _controller,
                              width: 100,
                              height: 12,
                              borderRadius: AppRadii.br10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ShimmerElement(
                          controller: _controller,
                          width: double.infinity,
                          height: 6,
                          borderRadius: AppRadii.br10,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ShimmerElement(
                        controller: _controller,
                        width: 36,
                        height: 36,
                        borderRadius: AppRadii.br20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _DottedBorderPainter(
                    color: colors.hairline2,
                    borderRadius: 16.0,
                  ),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPaint(
                  painter: _DottedBorderPainter(
                    color: colors.hairline2,
                    borderRadius: 16.0,
                  ),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomPaint(
                  painter: _DottedBorderPainter(
                    color: colors.hairline2,
                    borderRadius: 16.0,
                  ),
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerElement(
                controller: _controller,
                width: 80,
                height: 20,
                borderRadius: AppRadii.br10,
              ),
              _ShimmerElement(
                controller: _controller,
                width: 60,
                height: 14,
                borderRadius: AppRadii.br10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CustomPaint(
                  painter: _DottedBorderPainter(
                    color: colors.hairline2,
                    borderRadius: 12.0,
                  ),
                  child: SizedBox(
                    width: 96,
                    height: 132,
                  ),
                ),
              );
            },
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
    required this.borderRadius,
  });

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
