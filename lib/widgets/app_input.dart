import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:zapbook/theme/app_theme.dart';

class AppInput extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final String? initialValue;
  final Widget? trailing;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  const AppInput({
    super.key,
    this.icon,
    this.label,
    this.initialValue,
    this.trailing,
    this.controller,
    this.onChanged,
    this.hintText,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late TextEditingController _controller;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _hasValue = _controller.text.isNotEmpty;
    _controller.addListener(_updateValueStatus);
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_updateValueStatus);
      _controller = widget.controller!;
      _hasValue = _controller.text.isNotEmpty;
      _controller.addListener(_updateValueStatus);
    }
  }

  void _updateValueStatus() {
    final hasVal = _controller.text.isNotEmpty;
    if (hasVal != _hasValue) {
      setState(() {
        _hasValue = hasVal;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_updateValueStatus);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 9.0),
            child: Text(
              widget.label!,
              style: typography.body.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.0,
                letterSpacing: 0.02 * 12,
                color: semanticColors.slate,
              ),
            ),
          ),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: semanticColors.paper2,
            borderRadius: AppRadii.br16,
            border: Border.all(
              color: _hasValue
                  ? semanticColors.bitcoinTint2
                  : semanticColors.hairline2,
            ),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: semanticColors.slate),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  style: typography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.0,
                    color: _hasValue
                        ? semanticColors.ink
                        : semanticColors.slate,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: typography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.0,
                      color: semanticColors.slate,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 10),
                DefaultTextStyle(
                  style: typography.mono.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.0,
                    color: semanticColors.slate2,
                  ),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
