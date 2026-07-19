import 'dart:async';

import 'package:flutter/material.dart';

import 'package:zapbook/core/presentation/theme/app_theme.dart';

/// A small floating pill shown while the reader is 90%–99% through a book,
/// nudging them to mark it as finished.
///
/// It fades to a faint, non-distracting opacity after [fadeDelay] of no
/// interaction. Tapping it while faded just restores full opacity; tapping
/// it again while fully opaque triggers [onComplete].
class ReaderMarkCompletePill extends StatefulWidget {
  const ReaderMarkCompletePill({
    required this.visible,
    required this.onComplete,
    this.fadeDelay = const Duration(seconds: 5),
    this.fadedOpacity = 0.25,
    super.key,
  });

  final bool visible;
  final VoidCallback onComplete;
  final Duration fadeDelay;
  final double fadedOpacity;

  @override
  State<ReaderMarkCompletePill> createState() => _ReaderMarkCompletePillState();
}

class _ReaderMarkCompletePillState extends State<ReaderMarkCompletePill> {
  double _opacity = 1;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _scheduleFade();
  }

  @override
  void didUpdateWidget(covariant ReaderMarkCompletePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      // Newly shown (e.g. progress just crossed 90%): start fresh.
      setState(() => _opacity = 1);
      _scheduleFade();
    } else if (!widget.visible && oldWidget.visible) {
      _fadeTimer?.cancel();
      _opacity = 1;
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _scheduleFade() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer(widget.fadeDelay, () {
      if (mounted) setState(() => _opacity = widget.fadedOpacity);
    });
  }

  void _handleTap() {
    if (_opacity < 1) {
      // Faded pill: a tap just brings it back to full visibility.
      setState(() => _opacity = 1);
      _scheduleFade();
      return;
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final colors = context.colors;
    final typography = context.typography;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bitcoin,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: colors.white),
                const SizedBox(width: 8),
                Text(
                  'Mark as Complete',
                  style: typography.bodyS.copyWith(
                    color: colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
