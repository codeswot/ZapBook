import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/library/presentation/bloc/circles_cubit.dart';
import 'package:zapbook/features/library/presentation/bloc/circles_state.dart';
import 'package:zapbook/features/library/presentation/widgets/circle_tile.dart';
import 'package:zapbook/features/library/presentation/widgets/circles_empty.dart';
import 'package:zapbook/features/library/presentation/widgets/library_shimmer.dart';
import 'package:zapbook/theme/app_theme.dart';

class CirclesPage extends StatelessWidget {
  const CirclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CirclesCubit>(),
      child: const _CirclesView(),
    );
  }
}

class _CirclesView extends StatelessWidget {
  const _CirclesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        child: Column(
          children: const [
            _CirclesHeader(),
            Expanded(child: _CirclesBody()),
          ],
        ),
      ),
    );
  }
}

class _CirclesHeader extends StatelessWidget {
  const _CirclesHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CIRCLES',
            style: typography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.bitcoin,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Your circles',
            style: typography.h1.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclesBody extends StatelessWidget {
  const _CirclesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CirclesCubit, CirclesState>(
      builder: (context, state) {
        switch (state) {
          case CirclesLoading():
            return const LibraryShimmer();
          case CirclesEmpty():
            return const SingleChildScrollView(child: CirclesEmptyView());
          case CirclesError(:final message):
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.typography.body.copyWith(
                    color: context.colors.slate,
                  ),
                ),
              ),
            );
          case CirclesLoaded(:final circles):
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              itemCount: circles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => CircleTile(circle: circles[index]),
            );
        }
      },
    );
  }
}
