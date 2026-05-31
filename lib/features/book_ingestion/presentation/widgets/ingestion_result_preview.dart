import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class IngestionResultPreview extends StatelessWidget {
  const IngestionResultPreview({
    super.key,
    required this.coverImage,
    required this.onInspect,
  });

  final Uint8List? coverImage;
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Title',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Book Author',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Inspect ZBF',
          icon: Icons.travel_explore_outlined,
          variant: AppButtonVariant.tonal,
          fullWidth: true,
          onTap: onInspect,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
