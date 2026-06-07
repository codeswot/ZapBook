import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_body.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_error_view.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_header.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_shimmer.dart';
import 'package:zapbook/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => getIt<ProfileCubit>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ProfileHeader(),
            Expanded(
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) => switch (state) {
                  ProfileLoading() => const ProfileShimmer(),
                  ProfileError(:final message) => ProfileErrorView(
                    message: message,
                  ),
                  ProfileLoaded(:final profile, :final nwcWalletName) =>
                    ProfileBody(
                      profile: profile,
                      nwcWalletName: nwcWalletName,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
