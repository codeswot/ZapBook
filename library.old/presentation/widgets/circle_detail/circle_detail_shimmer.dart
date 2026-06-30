import 'package:flutter/material.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_detail/circle_detail_top_bar.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_shimmer.dart';

class CircleDetailShimmer extends StatelessWidget {
  const CircleDetailShimmer({super.key, required this.bookId});
  final String bookId;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppShimmer(
      child: Column(
        children: [
          CircleDetailTopBar(
            readersCount: 0,
            bookId: bookId,
            bookTitle: 'Loading circle...',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 18),
                _CardShimmer(colors: colors, height: 148),
                const SizedBox(height: 14),
                AppShimmerBox(
                  width: double.infinity,
                  height: 48,
                  borderRadius: AppRadii.br14,
                ),
                const SizedBox(height: 26),
                AppShimmerBox(
                  width: 100,
                  height: 18,
                  borderRadius: AppRadii.br10,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < 3; i++) ...[
                  _CardShimmer(colors: colors, height: 92),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer({required this.colors, required this.height});

  final SemanticColors colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: AppRadii.br16,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          AppShimmerBox(width: 56, height: 77, borderRadius: AppRadii.br12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerBox(
                  width: 80,
                  height: 10,
                  borderRadius: AppRadii.br10,
                ),
                const SizedBox(height: 8),
                AppShimmerBox(
                  width: double.infinity,
                  height: 6,
                  borderRadius: AppRadii.br10,
                ),
                const SizedBox(height: 12),
                AppShimmerBox(
                  width: 120,
                  height: 12,
                  borderRadius: AppRadii.br10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
