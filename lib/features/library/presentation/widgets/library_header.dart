import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_icon_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.isSearching,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSearch,
  });

  final bool isSearching;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: isSearching
          ? Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: searchController,
                    autofocus: true,
                    icon: LucideIcons.search,
                    hintText: 'Search books...',
                    onChanged: onSearchChanged,
                    trailing: searchController.text.isNotEmpty
                        ? BouncingInteractiveWidget(
                            onTap: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: colors.slate2,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                BouncingInteractiveWidget(
                  onTap: onToggleSearch,
                  child: Text(
                    'Cancel',
                    style: typography.body.copyWith(
                      color: colors.bitcoin,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Row(
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
                      onTap: onToggleSearch,
                      icon: LucideIcons.search,
                      size: 22,
                      color: colors.ink,
                      backgroundColor: colors.paper,
                    ),
                    const SizedBox(width: 12),
                    AppIconButton(
                      onTap: () =>
                          context.read<IngestionPageCubit>().pickBook(),
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
