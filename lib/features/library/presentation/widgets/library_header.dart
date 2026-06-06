import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_icon_button.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LIBRARY",
                style: typography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.bitcoin,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Your shelf",
                style: typography.h1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
            ],
          ),
          Row(
            children: [
              AppIconButton(
                onTap: () {},
                icon: LucideIcons.search,
                size: 22,
                color: colors.ink,
                backgroundColor: colors.paper,
              ),
              const SizedBox(width: 12),
              AppIconButton(
                onTap: () => context.read<IngestionPageCubit>().pickBook(),
                icon: LucideIcons.plus,
                size: 22,
                color: colors.bitcoinDark,
                backgroundColor: colors.bitcoin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
