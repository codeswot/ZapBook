import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_event.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_state.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_state.dart';
import 'package:zapbook/features/library/presentation/widgets/ingestion_progress_widget.dart';
import 'package:zapbook/features/library/presentation/widgets/book_wizard_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/ingestion_result_preview.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_prompt_sheet.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LibraryView();
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  void _inspect(BuildContext context, String zbfPath) {
    ZbfViewerRoute(zbfPath: zbfPath).push<void>(context);
  }

  void _handlePageCubitState(BuildContext context, IngestionPageState state) {
    if (state is IngestionPageFilePicked) {
      final completer = Completer<WizardData>();
      context.read<IngestionBloc>().add(
        IngestionStarted(state.file, wizardDataFuture: completer.future),
      );

      BookWizardSheet.show(
        context,
        completer: completer,
        rawTitle: state.rawTitle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<IngestionPageCubit, IngestionPageState>(
          listener: _handlePageCubitState,
        ),
        BlocListener<IngestionBloc, IngestionState>(
          listener: (context, state) {
            if (state is IngestionComplete ||
                state is IngestionNeedsAiProcessing) {
              final manifest = _manifestOf(state);
              CirclePromptSheet.show(
                context,
                manifest: manifest,
                onCreateCircle: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Circle created successfully!"),
                    ),
                  );
                },
                onJustRead: () => context.pop(),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: context.colors.paper,
        body: SafeArea(
          child: BlocBuilder<IngestionBloc, IngestionState>(
            builder: (context, state) {
              final zbfPath = _viewablePath(state);
              final hasBook = zbfPath != null;
              final manifest = _manifestOf(state);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: hasBook
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                IngestionResultPreview(
                                  coverImage: _coverImage(state),
                                  title: manifest?.title ?? 'Unknown Title',
                                  author: manifest?.author ?? 'Unknown Author',
                                  genre: manifest?.genre,
                                  onInspect: () => _inspect(context, zbfPath),
                                ),
                                const IngestionProgressWidget(),
                              ],
                            )
                          : _buildEmptyShelf(context),
                    ),
                  ),
                  if (hasBook)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: AppButton(
                        label: 'Pick a book',
                        icon: LucideIcons.bookOpen,
                        fullWidth: true,
                        onTap: () =>
                            context.read<IngestionPageCubit>().pickBook(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.bgElev,
        border: Border(bottom: BorderSide(color: context.colors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Your shelf",
            style: context.typography.h1.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.positive.withValues(alpha: 0.1),
              borderRadius: AppRadii.br999,
              border: Border.all(
                color: context.colors.positive.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.check,
                  size: 14,
                  color: context.colors.positive,
                ),
                const SizedBox(width: 6),
                Text(
                  "All set",
                  style: context.typography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.positive,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyShelf(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == 1;
            return Opacity(
              opacity: active ? 1.0 : 0.5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: 64,
                height: 92,
                decoration: BoxDecoration(
                  color: context.colors.paper3,
                  borderRadius: AppRadii.br12,
                  border: Border.all(
                    color: context.colors.hairline2,
                    width: 1.5,
                  ),
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

  String? _viewablePath(IngestionState state) => switch (state) {
    IngestionComplete(:final zbfPath) => zbfPath,
    IngestionNeedsAiProcessing(:final zbfPath) => zbfPath,
    _ => null,
  };

  Uint8List? _coverImage(IngestionState state) => switch (state) {
    IngestionComplete(:final coverImage) => coverImage,
    IngestionNeedsAiProcessing(:final coverImage) => coverImage,
    _ => null,
  };

  BookManifest? _manifestOf(IngestionState state) => switch (state) {
    IngestionComplete(:final manifest) => manifest,
    IngestionNeedsAiProcessing(:final manifest) => manifest,
    _ => null,
  };
}
