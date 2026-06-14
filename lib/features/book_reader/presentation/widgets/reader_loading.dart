import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/widgets/zb_shimmer.dart';

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

class ReaderPagePrepFailed extends StatelessWidget {
  const ReaderPagePrepFailed({
    required this.pageNumber,
    required this.onRetry,
    this.onSkip,
    super.key,
  });

  final int pageNumber;
  final VoidCallback onRetry;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 80,
        24,
        24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Couldn't prepare page $pageNumber",
            style: typography.h3.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Something held this page up. Try again, or skip ahead.',
            style: typography.bodyS.copyWith(color: colors.slate),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              BouncingInteractiveWidget(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bitcoin,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Retry',
                    style: typography.bodyS.copyWith(
                      color: colors.bitcoinDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (onSkip != null) ...[
                const SizedBox(width: 12),
                BouncingInteractiveWidget(
                  onTap: onSkip!,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.hairline2),
                    ),
                    child: Text(
                      'Skip',
                      style: typography.bodyS.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
