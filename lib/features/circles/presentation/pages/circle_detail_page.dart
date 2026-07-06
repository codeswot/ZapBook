import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/circle_detail_state.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_detail_shimmer.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_error_view.dart';
import 'package:zapbook/features/circles/presentation/widgets/circle_detail/circle_loaded_view.dart';
import 'package:zapbook/theme/app_theme.dart';

class CircleDetailPage extends StatelessWidget {
  const CircleDetailPage({super.key, required this.circleBookId});

  final String circleBookId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CircleDetailCubit>()..load(circleBookId),
      child: _CircleDetailView(circleBookId: circleBookId),
    );
  }
}

class _CircleDetailView extends StatelessWidget {
  const _CircleDetailView({required this.circleBookId});

  final String circleBookId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<CircleDetailCubit, CircleDetailState>(
          listener: (context, state) {
            if (state is CircleDetailClosed) context.pop();
          },
          builder: (context, state) {
            return switch (state) {
              CircleDetailLoaded() => CircleLoadedView(
                circleBookId: circleBookId,
                state: state,
              ),
              CircleDetailError(:final message) => CircleErrorView(
                message: message,
              ),
              _ => CircleDetailShimmer(circleBookId: circleBookId),
            };
          },
        ),
      ),
    );
  }
}
