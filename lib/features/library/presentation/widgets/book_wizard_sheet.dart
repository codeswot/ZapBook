import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_book_cover.dart';
import 'package:zapbook/widgets/app_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_chip.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/wizard_data.dart';
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/wizard/book_wizard_state.dart';

class BookWizardSheet extends StatefulWidget {
  const BookWizardSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required Completer<WizardData> completer,
    required String rawTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => BlocProvider<BookWizardCubit>(
        create: (_) =>
            getIt<BookWizardCubit>(param1: completer, param2: rawTitle),
        child: const BookWizardSheet(),
      ),
    );
  }

  @override
  State<BookWizardSheet> createState() => _BookWizardSheetState();
}

class _BookWizardSheetState extends State<BookWizardSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    final initialState = context.read<BookWizardCubit>().state;
    _titleController = TextEditingController(text: initialState.title);
    _authorController = TextEditingController(text: initialState.author ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final cubit = context.read<BookWizardCubit>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.cancel();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: AppSheet(
          child: BlocBuilder<BookWizardCubit, BookWizardState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SafeArea(child: Text('Book Details', style: typography.h3)),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBookCover(
                          width: 100,
                          height: 150,
                          title: state.title,
                          image: state.coverImage != null
                              ? MemoryImage(state.coverImage!)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              AppInput(
                                controller: _titleController,
                                label: 'Title',
                                onChanged: cubit.updateTitle,
                              ),
                              const SizedBox(height: 16),
                              AppInput(
                                controller: _authorController,
                                label: 'Author (Optional)',
                                onChanged: cubit.updateAuthor,
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'Pick Cover',
                                icon: Icons.image_outlined,
                                variant: AppButtonVariant.tonal,
                                fullWidth: true,
                                onTap: cubit.pickCoverImage,
                              ),
                              if (state.coverImage != null) ...[
                                const SizedBox(height: 8),
                                AppButton(
                                  label: 'Remove Cover',
                                  icon: Icons.delete_outline,
                                  variant: AppButtonVariant.ghost,
                                  fullWidth: true,
                                  onTap: cubit.removeCoverImage,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Genre',
                      style: typography.bodyL.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.availableGenres.map((genre) {
                        final isSelected = state.genre == genre;
                        return AppChip(
                          label: genre,
                          selected: isSelected,
                          tone: isSelected ? AppChipTone.zap : null,
                          onTap: () =>
                              cubit.updateGenre(isSelected ? '' : genre),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Continue',
                      fullWidth: true,
                      onTap: () {
                        cubit.submit();
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
