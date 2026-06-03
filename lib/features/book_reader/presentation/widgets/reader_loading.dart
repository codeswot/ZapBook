import 'package:flutter/material.dart';
import 'package:zapbook/features/library/presentation/widgets/zb_shimmer.dart';

class ReaderPageLoading extends StatelessWidget {
  const ReaderPageLoading({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 80,
        24,
        24,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ZbShimmer(message: message),
      ),
    );
  }
}
