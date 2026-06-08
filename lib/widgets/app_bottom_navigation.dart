import 'package:flutter/material.dart';
import 'package:zapbook/theme/app_radii.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AppBottomNavigationItem {
  final String id;
  final String label;
  final IconData icon;

  const AppBottomNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class AppBottomNavigation extends StatelessWidget {
  final String activeId;
  final ValueChanged<String>? onSelected;
  final double safeAreaBottom;

  const AppBottomNavigation({
    super.key,
    required this.activeId,
    this.onSelected,
    this.safeAreaBottom = 30.0,
  });

  static const List<AppBottomNavigationItem> defaultItems = [
    AppBottomNavigationItem(id: 'home', label: 'Home', icon: LucideIcons.home),
    AppBottomNavigationItem(
      id: 'circles',
      label: 'Circles',
      icon: LucideIcons.users,
    ),
    AppBottomNavigationItem(
      id: 'cheers',
      label: 'Cheers',
      icon: LucideIcons.bell,
    ),
    AppBottomNavigationItem(
      id: 'library',
      label: 'Library',
      icon: LucideIcons.book,
    ),
    AppBottomNavigationItem(id: 'you', label: 'You', icon: LucideIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.colors;
    final typography = context.typography;

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: safeAreaBottom),
      decoration: BoxDecoration(
        color: semanticColors.paper2,
        border: Border(
          top: BorderSide(color: semanticColors.ink.withValues(alpha: 0.09)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: defaultItems.map((item) {
          final isOn = item.id == activeId;

          return BouncingInteractiveWidget(
            onTap: onSelected != null ? () => onSelected!(item.id) : null,
            child: SizedBox(
              width: 62,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isOn
                          ? semanticColors.bitcoinTint
                          : semanticColors.transparent,
                      borderRadius: AppRadii.br999,
                      border: Border.all(
                        color: isOn
                            ? semanticColors.bitcoinTint2
                            : semanticColors.transparent,
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: isOn
                          ? semanticColors.bitcoin2
                          : semanticColors.slate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: typography.body.copyWith(
                      fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 10.5,
                      height: 1.0,
                      color: isOn ? semanticColors.ink : semanticColors.slate,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
