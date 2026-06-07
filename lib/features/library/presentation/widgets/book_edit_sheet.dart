import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/presentation/bloc/book_edit_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/book_edit_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_chip.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';

class BookEditSheet extends StatelessWidget {
  const BookEditSheet({super.key, required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookEditCubit>(param1: book),
      child: const _Body(),
    );
  }

  static Future<void> show(BuildContext context, LibraryBook book) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BookEditSheet(book: book),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _titleController = TextEditingController(
    text: context.read<BookEditCubit>().state.title,
  );
  late final _authorController = TextEditingController(
    text: context.read<BookEditCubit>().state.author,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookEditCubit, BookEditState>(
      listener: (context, state) {
        if (state.error != null) {
          context.toast.showError(state.error!);
        }
      },
      builder: (context, state) {
        final typography = context.typography;
        final cubit = context.read<BookEditCubit>();

        ImageProvider? coverImage;
        if (state.newCover != null) {
          coverImage = MemoryImage(state.newCover!);
        } else {
          final path = state.book.coverPath;
          coverImage = path != null ? FileImage(File(path)) : null;
        }

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit details', style: typography.h3),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBookCover(
                      width: 100,
                      height: 150,
                      title: state.title,
                      image: coverImage,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          AppInput(
                            controller: _titleController,
                            label: 'Title',
                            onChanged: cubit.setTitle,
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            controller: _authorController,
                            label: 'Author (Optional)',
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Change Cover',
                            icon: Icons.image_outlined,
                            variant: AppButtonVariant.tonal,
                            fullWidth: true,
                            onTap: state.saving ? null : cubit.pickCover,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Genre',
                  style: typography.bodyL.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.genres.map((genre) {
                    final selected = state.genre == genre;
                    return AppChip(
                      label: genre,
                      selected: selected,
                      tone: selected ? AppChipTone.zap : null,
                      onTap: () => cubit.setGenre(selected ? null : genre),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: state.saving ? 'Saving…' : 'Save changes',
                  fullWidth: true,
                  onTap: state.saving
                      ? null
                      : () async {
                          final updated = await cubit.save();
                          if (updated != null && context.mounted) {
                            final coverPath = updated.coverPath;
                            if (state.newCover != null && coverPath != null) {
                              await FileImage(File(coverPath)).evict();
                            }
                            if (context.mounted) {
                              context.pop(updated);
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
