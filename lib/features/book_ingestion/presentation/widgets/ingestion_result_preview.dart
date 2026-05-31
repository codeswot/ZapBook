import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_chip.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class IngestionResultPreview extends StatelessWidget {
  const IngestionResultPreview({
    super.key,
    required this.coverImage,
    required this.title,
    required this.author,
    this.genre,
    required this.onInspect,
  });

  final Uint8List? coverImage;
  final String title;
  final String author;
  final String? genre;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final cover = coverImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (cover != null)
              Center(
                child: BouncingInteractiveWidget(
                  onTap: onInspect,
                  scaleFactor: 0.97,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      cover,
                      width: 160,
                      height: 240,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    author,
                    style: TextStyle(fontSize: 14, color: context.colors.mint),
                  ),
                  if (genre != null) ...[
                    const SizedBox(height: 12),
                    AppChip(label: genre!),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
