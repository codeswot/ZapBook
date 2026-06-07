import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:zapbook/core/data/datasources/genre_datasource.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/usecases/update_book_metadata.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_chip.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_sheet.dart';

class BookEditSheet extends StatefulWidget {
  const BookEditSheet({super.key, required this.book});

  final LibraryBook book;

  static Future<void> show(BuildContext context, LibraryBook book) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BookEditSheet(book: book),
    );
  }

  @override
  State<BookEditSheet> createState() => _BookEditSheetState();
}

class _BookEditSheetState extends State<BookEditSheet> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.book.title,
  );
  late final TextEditingController _authorController = TextEditingController(
    text: widget.book.author,
  );

  late String? _genre = widget.book.genre;
  Uint8List? _newCover;
  bool _saving = false;

  final List<String> _genres = getIt<GenreDataSource>().getGenres();

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final bytes = await getIt<FilePickerService>().pickImage();
    if (bytes != null && mounted) {
      setState(() => _newCover = bytes);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      final updated = await getIt<UpdateBookMetadata>()(
        widget.book.id,
        title: _titleController.text,
        author: _authorController.text,
        genre: _genre,
        coverImage: _newCover,
      );
      final coverPath = updated.coverPath;
      if (_newCover != null && coverPath != null) {
        await FileImage(File(coverPath)).evict();
      }
      navigator.pop();
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        context.toast.showError('Failed to save changes');
      }
    }
  }

  ImageProvider? get _coverImage {
    if (_newCover != null) {
      return MemoryImage(_newCover!);
    }
    final path = widget.book.coverPath;
    return path != null ? FileImage(File(path)) : null;
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AppSheet(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SafeArea(child: Text('Edit details', style: typography.h3)),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBookCover(
                    width: 100,
                    height: 150,
                    title: _titleController.text,
                    image: _coverImage,
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
                          onTap: _pickCover,
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
                children: _genres.map((genre) {
                  final selected = _genre == genre;
                  return AppChip(
                    label: genre,
                    selected: selected,
                    tone: selected ? AppChipTone.zap : null,
                    onTap: () =>
                        setState(() => _genre = selected ? null : genre),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _saving ? 'Saving…' : 'Save changes',
                fullWidth: true,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
