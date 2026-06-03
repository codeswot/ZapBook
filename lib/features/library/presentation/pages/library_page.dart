import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:zapbook/features/book_ingestion/domain/entities/wizard_data.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/zbf_viewer_page.dart';
import 'package:zapbook/features/library/presentation/widgets/book_wizard_sheet.dart';
import 'package:zapbook/features/library/domain/entities/ingestion_job.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_state.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';
import 'package:zapbook/features/library/presentation/widgets/library_book_tile.dart';
import 'package:zapbook/features/library/presentation/widgets/library_processing_tile.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_cubit.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/page/ingestion_page_state.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_icon_button.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

void _openReader(BuildContext context, String zbfPath) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => ZbfViewerPage(zbfPath: zbfPath)),
  );
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LibraryView();
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  void _onPageCubitState(BuildContext context, IngestionPageState state) {
    if (state is IngestionPageFilePicked) {
      final completer = Completer<WizardData>();
      context.read<IngestionQueueCubit>().enqueue(
        state.file,
        wizardDataFuture: completer.future,
      );
      BookWizardSheet.show(
        context,
        completer: completer,
        rawTitle: state.rawTitle,
      );
    } else if (state is IngestionPageError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IngestionPageCubit, IngestionPageState>(
      listener: _onPageCubitState,
      child: Scaffold(
        backgroundColor: context.colors.paper,
        body: SafeArea(
          child: Column(
            children: const [
              LibraryHeader(),
              Expanded(child: _LibraryBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IngestionQueueCubit, IngestionQueueState>(
      builder: (context, queue) {
        return BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, library) {
            final jobs = queue.visibleJobs;
            final books = switch (library) {
              LibraryLoaded(:final books) => books,
              _ => const <LibraryBook>[],
            };

            if (library is LibraryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (books.isEmpty && jobs.isEmpty) {
              return const SingleChildScrollView(child: LibraryEmpty());
            }
            return _Shelf(jobs: jobs, books: books);
          },
        );
      },
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.jobs, required this.books});

  final List<IngestionJob> jobs;
  final List<LibraryBook> books;

  @override
  Widget build(BuildContext context) {
    final hero = books.isNotEmpty ? books.first : null;
    final tileCount = jobs.length + books.length;

    return CustomScrollView(
      slivers: [
        if (hero != null)
          SliverToBoxAdapter(child: _ContinueReadingCard(book: hero)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              'All Books',
              style: context.typography.eyebrow.copyWith(
                color: context.colors.slate,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.727,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < jobs.length) {
                return LibraryProcessingTile(job: jobs[index]);
              }
              return LibraryBookTile(book: books[index - jobs.length]);
            }, childCount: tileCount),
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final cover = book.coverPath;
    final image = cover != null && File(cover).existsSync()
        ? FileImage(File(cover))
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: BouncingInteractiveWidget(
        onTap: () => _openReader(context, book.zbfPath),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.paper3,
            borderRadius: AppRadii.br16,
            border: Border.all(color: colors.hairline),
          ),
          child: Row(
            children: [
              AppBookCover(width: 56, height: 77, image: image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONTINUE READING',
                      style: typography.caption.copyWith(
                        color: colors.bitcoin,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.h3.copyWith(color: colors.ink),
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.bodyS.copyWith(color: colors.slate),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppIconButton(
                onTap: () => _openReader(context, book.zbfPath),
                icon: LucideIcons.bookOpen,
                size: 20,
                color: colors.paper,
                backgroundColor: colors.bitcoin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                color: colors.paper,
                backgroundColor: colors.bitcoin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
}
