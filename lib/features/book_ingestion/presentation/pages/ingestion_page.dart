import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/zbf/zbf.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_event.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_state.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_state.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/ingestion_progress_widget.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/book_wizard_sheet.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/ingestion_result_preview.dart';

class IngestionPage extends StatelessWidget {
  const IngestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<IngestionBloc>(create: (_) => getIt<IngestionBloc>()),
        BlocProvider<IngestionPageCubit>(
          create: (_) => getIt<IngestionPageCubit>(),
        ),
      ],
      child: const _IngestionView(),
    );
  }
}

class _IngestionView extends StatefulWidget {
  const _IngestionView();

  @override
  State<_IngestionView> createState() => _IngestionViewState();
}

class _IngestionViewState extends State<_IngestionView> {
  bool _showCirclePrompt = false;

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
            if (state is IngestionComplete || state is IngestionNeedsAiProcessing) {
              setState(() {
                _showCirclePrompt = true;
              });
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

              return Stack(
                children: [
                  Opacity(
                    opacity: _showCirclePrompt ? 0.5 : 1.0,
                    child: AbsorbPointer(
                      absorbing: _showCirclePrompt,
                      child: Column(
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
                                onTap: () => context.read<IngestionPageCubit>().pickBook(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_showCirclePrompt && hasBook)
                    _buildCirclePrompt(context, manifest, () {
                      setState(() {
                        _showCirclePrompt = false;
                      });
                    }),
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
        border: Border(
          bottom: BorderSide(color: context.colors.hairline),
        ),
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
              border: Border.all(color: context.colors.positive.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.check, size: 14, color: context.colors.positive),
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

  Widget _buildCirclePrompt(BuildContext context, BookManifest? manifest, VoidCallback onJustRead) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.bgElev,
          border: Border(
            top: BorderSide(color: context.colors.hairline),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: AppRadii.rad24,
            topRight: AppRadii.rad24,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: context.colors.plumTint,
                borderRadius: AppRadii.br24,
                border: Border.all(color: context.colors.plumTint2),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.users,
                color: context.colors.plum,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Nice — first book added",
              style: context.typography.bodyS.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.plum,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start a reading circle with ${manifest?.title ?? 'your new book'}?",
              style: context.typography.h2.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              "Invite up to 100 people to read it together. Anyone in the circle can zap anyone who hits a milestone.",
              style: context.typography.body.copyWith(
                color: context.colors.slate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            AppButton(
              label: "Yes, create a circle",
              variant: AppButtonVariant.purple,
              fullWidth: true,
              icon: LucideIcons.users,
              onTap: () {
                setState(() {
                  _showCirclePrompt = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Circle created successfully!")),
                );
              },
            ),
            const SizedBox(height: 11),
            AppButton(
              label: "Not now — just read",
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onTap: onJustRead,
            ),
          ],
        ),
      ),
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
