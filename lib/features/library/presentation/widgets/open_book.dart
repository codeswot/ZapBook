import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/router/app_router.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/library_cubit.dart';

void openBook(BuildContext context, LibraryBook book) {
  context.read<LibraryCubit>().markOpened(book.id);
  ZbfViewerRoute(zbfPath: book.zbfPath).push(context);
}
