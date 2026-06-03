import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/zbf_viewer_page.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';

void openBook(BuildContext context, LibraryBook book) {
  context.read<LibraryCubit>().markOpened(book.id);
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => ZbfViewerPage(zbfPath: book.zbfPath),
    ),
  );
}
