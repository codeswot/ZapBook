import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_cubit.dart';
import 'package:zapbook/core/presentation/bloc/circle_operations/circle_operations_state.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/constants/book_genres.dart';
import 'package:zapbook/core/data/infrastructure/file_picker_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_book_cover.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_chip.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';

class BookEditSheet extends StatelessWidget {
  const BookEditSheet({super.key, required this.book});

  final CircleBook book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleOperationsCubit>(),
      child: _Body(book: book),
    );
  }

  static Future<void> show(BuildContext context, CircleBook book) {
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
  const _Body({required this.book});

  final CircleBook book;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _titleController = TextEditingController(text: widget.book.title);
  late final _authorController = TextEditingController(
    text: widget.book.author,
  );

  String? _genre;
  Uint8List? _newCover;
  Future<GroupImagePrepared>? _pendingCoverUpload;

  @override
  void initState() {
    super.initState();
    _genre = widget.book.genre;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final bytes = await getIt<FilePickerService>().pickImage();
    if (bytes != null && mounted) {
      setState(() {
        _newCover = bytes;
        _pendingCoverUpload = context
            .read<CircleOperationsCubit>()
            .prepareCover(bytes);
      });
    }
  }

  Future<void> _save(CircleOperationsCubit cubit) async {
    final title = _titleController.text;
    final author = _authorController.text;
    final genre = _genre;
    final coverBytes = _newCover;
    final pendingCoverUpload = _pendingCoverUpload;
    final book = widget.book;

    context.pop();

    cubit.saveBookEditsInBackground(
      book: book,
      title: title,
      author: author,
      genre: genre,
      coverBytes: coverBytes,
      pendingCoverUpload: pendingCoverUpload,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CircleOperationsCubit, CircleOperationsState>(
      listener: (context, state) {
        if (state is CircleOperationsFailure) {
          context.toast.showError(state.error);
        }
      },
      builder: (context, state) {
        final typography = context.typography;
        final cubit = context.read<CircleOperationsCubit>();
        final saving = state is CircleOperationsLoading;

        ImageProvider? coverImage;
        if (_newCover != null) {
          coverImage = MemoryImage(_newCover!);
        } else {
          final path = widget.book.coverPath;
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
                      title: _titleController.text,
                      image: coverImage,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          AppInput(
                            controller: _titleController,
                            label: 'Title',
                            onChanged: (_) => setState(() {}),
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
                            onTap: saving ? null : _pickCover,
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
                  children: bookGenres.map((genre) {
                    final selected = _genre == genre;
                    return AppChip(
                      label: genre,
                      selected: selected,
                      tone: selected ? AppChipTone.zap : null,
                      onTap: () {
                        setState(() {
                          _genre = selected ? null : genre;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: saving ? 'Saving…' : 'Save changes',
                  fullWidth: true,
                  onTap: saving ? null : () => _save(cubit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
