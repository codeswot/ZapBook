import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart';
import 'package:zapbook/core/domain/heads_up_message.dart';

class AppHeadsUpBanner extends StatelessWidget {
  const AppHeadsUpBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeadsUpCubit, List<HeadsUpMessage>>(
      builder: (context, headsUpState) {
        final activeBanners = headsUpState;

        final Widget child = activeBanners.isEmpty
            ? const SizedBox.shrink()
            : Stack(children: activeBanners.map((m) => m.child).toList());

        final String key = activeBanners.isNotEmpty
            ? activeBanners.last.id
            : 'empty';
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey(key), child: child),
        );
      },
    );
  }
}
