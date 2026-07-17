import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/presentation/router/app_router.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';

void openBook(BuildContext context, CircleBook book) {
  context.read<LibraryCubit>().onBookOpened(book);
  ZbfViewerRoute(
    zbfPath: book.zbfPath,
    bookTitle: book.title,
    coverPath: book.coverPath,
    circleDirId: book.circleDirId,
    groupId: book.id,
  ).push(context);
}
