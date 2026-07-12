import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/theme/app_theme.dart';

import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/quiz_cubit.dart';

class ReaderQuizPill extends StatelessWidget {
  const ReaderQuizPill({required this.state, super.key});

  final QuizCubitState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuizCubit>();
    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Material(
        color: context.colors.transparent,
        child: state.screen == QuizScreenState.reveal
            ? _QuizReveal(state: state, cubit: cubit)
            : _QuizActive(state: state, cubit: cubit),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.paper3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.hairline2),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuizActive extends StatelessWidget {
  const _QuizActive({required this.state, required this.cubit});

  final QuizCubitState state;
  final QuizCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final set = state.set;
    if (set == null || state.currentIndex >= set.questions.length) {
      return const SizedBox.shrink();
    }
    final question = set.questions[state.currentIndex];

    return _QuizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPREHENSION · ${state.currentIndex + 1}/${set.questions.length}',
                style: typography.caption.copyWith(
                  color: colors.bitcoin,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              GestureDetector(
                onTap: cubit.skip,
                child: Text(
                  'Skip',
                  style: typography.bodyS.copyWith(
                    color: colors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.text,
            style: typography.bodyL.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BouncingInteractiveWidget(
                onTap: () => cubit.answer(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.hairline2),
                  ),
                  child: Text(
                    question.options[i],
                    style: typography.bodyS.copyWith(color: colors.ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizReveal extends StatelessWidget {
  const _QuizReveal({required this.state, required this.cubit});

  final QuizCubitState state;
  final QuizCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final pct = ((state.score ?? 0) * 100).round();
    final total = state.set?.questions.length ?? 0;
    final correct = ((state.score ?? 0) * total).round();

    return _QuizCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct%',
                  style: typography.h2.copyWith(
                    color: colors.bitcoin,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$correct of $total recalled',
                  style: typography.bodyS.copyWith(color: colors.slate),
                ),
              ],
            ),
          ),
          BouncingInteractiveWidget(
            onTap: cubit.dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bitcoin,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Done',
                style: typography.bodyS.copyWith(
                  color: colors.bitcoinDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
