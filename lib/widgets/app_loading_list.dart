import 'package:flutter/material.dart';

import 'package:zapbook/widgets/app_shimmer.dart';

class AppLoadingList extends StatelessWidget {
  const AppLoadingList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const AppShimmerBox(width: 36, height: 36, shape: BoxShape.circle),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppShimmerBox(width: (i == 0 ? 160 : i == 1 ? 120 : 140).toDouble(), height: 14),
                        const SizedBox(height: 8),
                        AppShimmerBox(width: (i == 0 ? 100 : 80).toDouble(), height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
