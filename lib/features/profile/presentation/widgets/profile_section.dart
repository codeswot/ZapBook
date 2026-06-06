import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.label, required this.tiles});

  final String label;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        children.add(
          Divider(height: 1, thickness: 1, color: colors.hairline),
        );
      }
      children.add(tiles[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.typography.eyebrow.copyWith(color: colors.slate2),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}
