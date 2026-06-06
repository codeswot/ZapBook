import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_shimmer.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _WalletSkeleton(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _StatSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _StatSkeleton()),
              ],
            ),
            SizedBox(height: 26),
            AppShimmerBox(width: 70, height: 11),
            SizedBox(height: 16),
            _TileSkeleton(),
            SizedBox(height: 8),
            _TileSkeleton(),
            SizedBox(height: 26),
            AppShimmerBox(width: 50, height: 11),
            SizedBox(height: 16),
            _TileSkeleton(),
            SizedBox(height: 8),
            _TileSkeleton(),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final colors = context.colors;
  return BoxDecoration(
    color: colors.paper2,
    borderRadius: AppRadii.br24,
    border: Border.all(color: colors.ink.withValues(alpha: 0.09)),
  );
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Row(
        children: const [
          AppShimmerBox(width: 44, height: 44, borderRadius: AppRadii.br12),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmerBox(width: 90, height: 11),
                SizedBox(height: 8),
                AppShimmerBox(width: 120, height: 18),
              ],
            ),
          ),
          AppShimmerBox(width: 72, height: 38, borderRadius: AppRadii.br10),
        ],
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper2,
        borderRadius: AppRadii.br16,
        border: Border.all(color: colors.ink.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppShimmerBox(width: 18, height: 18, borderRadius: AppRadii.br6),
          SizedBox(height: 14),
          AppShimmerBox(width: 30, height: 18),
          SizedBox(height: 6),
          AppShimmerBox(width: 50, height: 10),
        ],
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        AppShimmerBox(width: 38, height: 38, borderRadius: AppRadii.br10),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerBox(width: 110, height: 13),
              SizedBox(height: 7),
              AppShimmerBox(width: 160, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
