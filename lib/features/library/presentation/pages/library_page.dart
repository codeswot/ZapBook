import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/bloc/book_text_search_cubit.dart';
import 'package:zapbook/features/library/presentation/widgets/book_wizard_sheet.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_orchestrator_cubit.dart';
import 'package:zapbook/features/library/presentation/widgets/library_body.dart';
import 'package:zapbook/features/library/presentation/widgets/library_header.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/page/ingestion_page_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookTextSearchCubit>(
      create: (_) => getIt<BookTextSearchCubit>(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<BookTextSearchCubit>().query(query);
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        context.read<BookTextSearchCubit>().clear();
      }
    });
  }

  Future<void> _onPageCubitState(
    BuildContext context,
    IngestionPageState state,
  ) async {
    if (state is IngestionPageError) {
      context.toast.showError(state.message);
      return;
    }
    if (state is! IngestionPageFilePicked) {
      return;
    }

    final orchestrator = getIt<IngestionOrchestratorCubit>();
    if (!context.mounted) {
      return;
    }

    final completer = Completer<WizardData>();
    orchestrator.startIngestion(
      state.file,
      completer.future,
      state.contentHash,
    );

    BookWizardSheet.show(
      context,
      completer: completer,
      initialData: WizardInitialData(
        title: state.rawTitle,
        author: state.author,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IngestionPageCubit, IngestionPageState>(
      listenWhen: (_, curr) =>
          curr is IngestionPageFilePicked || curr is IngestionPageError,
      listener: _onPageCubitState,
      child: Scaffold(
        backgroundColor: context.colors.paper,
        body: SafeArea(
          child: Column(
            children: [
              LibraryHeader(
                isSearching: _isSearching,
                searchQuery: _searchQuery,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onToggleSearch: _toggleSearch,
              ),
              Expanded(child: LibraryBody(searchQuery: _searchQuery)),
            ],
          ),
        ),
      ),
    );
  }
}
