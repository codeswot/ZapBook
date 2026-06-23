import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_view.dart';

class CheersPage extends StatelessWidget {
  const CheersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheersCubit>(
      create: (_) => getIt<CheersCubit>(),
      child: const CheersView(),
    );
  }
}
