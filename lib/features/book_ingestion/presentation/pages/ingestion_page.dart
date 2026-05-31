import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/widgets/app_button.dart';

import 'package:zapbook/zbf/zbf.dart';


import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/router/app_router.dart';
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
        BlocProvider<IngestionBloc>(
          create: (_) => getIt<IngestionBloc>(),
        ),
        BlocProvider<IngestionPageCubit>(
          create: (_) => getIt<IngestionPageCubit>(),
        ),
      ],
      child: const _IngestionView(),
    );
  }
}

class _IngestionView extends StatelessWidget {
  const _IngestionView();

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
    return BlocListener<IngestionPageCubit, IngestionPageState>(
      listener: _handlePageCubitState,
      child: Scaffold(
        appBar: AppBar(title: const Text('ZapBook')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const IngestionProgressWidget(),
                const Spacer(),
                BlocBuilder<IngestionBloc, IngestionState>(
                  builder: (context, state) {
                    final zbfPath = _viewablePath(state);
                    if (zbfPath == null) {
                      return const SizedBox.shrink();
                    }
                    final manifest = _manifestOf(state);
                    return IngestionResultPreview(
                      coverImage: _coverImage(state),
                      title: manifest?.title ?? 'Unknown Title',
                      author: manifest?.author ?? 'Unknown Author',
                      genre: manifest?.genre,
                      onInspect: () => _inspect(context, zbfPath),
                    );
                  },
                ),
                AppButton(
                  label: 'Pick a book',
                  icon: Icons.menu_book_outlined,
                  fullWidth: true,
                  onTap: () => context.read<IngestionPageCubit>().pickBook(),
                ),
              ],
            ),
          ),
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
