import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/ingestion_queue_state.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart'
    hide LibraryEmpty;
import 'package:zapbook/features/library/presentation/widgets/library_empty.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_prompt_sheet.dart';
import 'package:zapbook/features/library/presentation/widgets/shelf.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/widgets/library_shimmer.dart';

class LibraryBody extends StatelessWidget {
  const LibraryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IngestionQueueCubit, IngestionQueueState>(
      builder: (context, queue) {
        return BlocConsumer<LibraryCubit, LibraryState>(
          listener: (context, library) {
            if (library is LibraryLoaded && library.showCirclePrompt && library.books.isNotEmpty) {
              CirclePromptSheet.show(context, library.books.first);
              context.read<LibraryCubit>().dismissCirclePrompt();
            }
          },
          builder: (context, library) {
            final jobs = queue.visibleJobs;
            final books = switch (library) {
              LibraryLoaded(:final books) => books,
              _ => const <LibraryBook>[],
            };

            if (library is LibraryLoading) {
              return const LibraryShimmer();
            }
            if (books.isEmpty && jobs.isEmpty) {
              return const SingleChildScrollView(child: LibraryEmpty());
            }
            return Shelf(jobs: jobs, books: books);
          },
        );
      },
    );
  }
}
