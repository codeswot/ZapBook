// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_workspace/components/app_avatar.dart'
    as _widgetbook_workspace_components_app_avatar;
import 'package:widgetbook_workspace/components/app_banner.dart'
    as _widgetbook_workspace_components_app_banner;
import 'package:widgetbook_workspace/components/app_book_cover.dart'
    as _widgetbook_workspace_components_app_book_cover;
import 'package:widgetbook_workspace/components/app_bottom_navigation.dart'
    as _widgetbook_workspace_components_app_bottom_navigation;
import 'package:widgetbook_workspace/components/app_button.dart'
    as _widgetbook_workspace_components_app_button;
import 'package:widgetbook_workspace/components/app_card.dart'
    as _widgetbook_workspace_components_app_card;
import 'package:widgetbook_workspace/components/app_celebration_card.dart'
    as _widgetbook_workspace_components_app_celebration_card;
import 'package:widgetbook_workspace/components/app_chip.dart'
    as _widgetbook_workspace_components_app_chip;
import 'package:widgetbook_workspace/components/app_input.dart'
    as _widgetbook_workspace_components_app_input;
import 'package:widgetbook_workspace/components/app_pill.dart'
    as _widgetbook_workspace_components_app_pill;
import 'package:widgetbook_workspace/components/app_progress.dart'
    as _widgetbook_workspace_components_app_progress;
import 'package:widgetbook_workspace/components/app_reaction.dart'
    as _widgetbook_workspace_components_app_reaction;
import 'package:widgetbook_workspace/components/app_row.dart'
    as _widgetbook_workspace_components_app_row;
import 'package:widgetbook_workspace/components/app_sats.dart'
    as _widgetbook_workspace_components_app_sats;
import 'package:widgetbook_workspace/components/app_sheet.dart'
    as _widgetbook_workspace_components_app_sheet;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'AppAvatar',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_avatar
                .buildAppAvatarUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppBanner',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Info Banner',
            builder: _widgetbook_workspace_components_app_banner
                .buildInfoBannerUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppBookCover',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_book_cover
                .buildAppBookCoverUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'With Image',
            builder: _widgetbook_workspace_components_app_book_cover
                .buildAppBookCoverWithImageUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppBottomNavigation',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_bottom_navigation
                .buildAppBottomNavigationUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppButton',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Primary',
            builder: _widgetbook_workspace_components_app_button
                .buildPrimaryAppButtonUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Purple',
            builder: _widgetbook_workspace_components_app_button
                .buildPurpleAppButtonUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Tonal',
            builder: _widgetbook_workspace_components_app_button
                .buildTonalAppButtonUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppCard',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_card
                .buildDefaultAppCardUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppCelebrationCard',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_celebration_card
                .buildDefaultAppCelebrationCardUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppChip',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_chip
                .buildDefaultAppChipUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Zap Tone (Selected)',
            builder: _widgetbook_workspace_components_app_chip
                .buildZapAppChipUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppInput',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_input
                .buildDefaultAppInputUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppPill',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_pill
                .buildDefaultAppPillUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppProgress',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_progress
                .buildDefaultAppProgressUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppReaction',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Active',
            builder: _widgetbook_workspace_components_app_reaction
                .buildActiveAppReactionUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_reaction
                .buildDefaultAppReactionUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppRow',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_row
                .buildDefaultAppRowUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppSats',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder:
                _widgetbook_workspace_components_app_sats.buildAppSatsUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppSheet',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _widgetbook_workspace_components_app_sheet
                .buildDefaultAppSheetUseCase,
          ),
        ],
      ),
    ],
  ),
];
