import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';

class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  static AnimationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_AppShimmerScope>();
    assert(scope != null, 'AppShimmerBox must be wrapped in an AppShimmer');
    return scope!.controller;
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AppShimmerScope(controller: _controller, child: widget.child);
  }
}

class _AppShimmerScope extends InheritedWidget {
  const _AppShimmerScope({required this.controller, required super.child});

  final AnimationController controller;

  @override
  bool updateShouldNotify(_AppShimmerScope oldWidget) =>
      oldWidget.controller != controller;
}

class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = AppShimmer.of(context);
    final radius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(8));

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
          borderRadius: radius,
          shape: shape,
        ),
      ),
    );
  }
}
