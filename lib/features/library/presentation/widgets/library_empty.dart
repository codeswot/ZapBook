import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_button.dart';

class LibraryEmpty extends StatelessWidget {
  const LibraryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == 1;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: 64,
              height: 92,
              decoration: BoxDecoration(
                color: context.colors.paper3.withValues(
                  alpha: active ? 1.0 : 0.5,
                ),
                borderRadius: AppRadii.br12,
                border: Border.all(
                  color: context.colors.hairline2.withValues(
                    alpha: active ? 1.0 : 0.5,
                  ),
                  width: 1.5,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 30),
        Text(
          "Your shelf is empty",
          style: context.typography.h2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Add a book to start reading — drop an ePub, paste a link, or pick a free classic.",
            style: context.typography.bodyS.copyWith(
              color: context.colors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 26),
        AppButton(
          label: "Add your first book",
          icon: LucideIcons.plus,
          onTap: () => context.read<IngestionPageCubit>().pickBook(),
        ),
      ],
    );
  }
}
