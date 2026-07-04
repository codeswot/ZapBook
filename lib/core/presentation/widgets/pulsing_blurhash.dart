import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class PulsingBlurHash extends StatefulWidget {
  final String blurhash;
  
  const PulsingBlurHash({super.key, required this.blurhash});

  @override
  State<PulsingBlurHash> createState() => _PulsingBlurHashState();
}

class _PulsingBlurHashState extends State<PulsingBlurHash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: child,
        );
      },
      child: BlurHash(
        hash: widget.blurhash,
        imageFit: BoxFit.cover,
      ),
    );
  }
}
