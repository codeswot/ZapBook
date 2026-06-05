import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_banner.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_step_intro.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ObProfileView extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;
  final TextEditingController displayNameController;

  const ObProfileView({
    super.key,
    required this.state,
    required this.cubit,
    required this.displayNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ObStepIntro(
          icon: LucideIcons.userCircle,
          accentColor: context.colors.nostr,
          accentDim: context.colors.nostrTint,
          accentLine: context.colors.nostrTint2,
          over: "Step 4 · Profile",
          title: "Your reader persona",
          description:
              "A fun name and picture so your circle knows who they're reading with. All optional.",
        ),
        const SizedBox(height: 26),
        if (state.isFetchingMetadata)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.colors.nostr,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Loading your profile…",
                  style: context.typography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.slate,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Center(
            child: Stack(
              children: [
                AppProfileAvatar(
                  url: state.picture,
                  size: 88,
                  borderColor: context.colors.nostrTint2,
                ),
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: BouncingInteractiveWidget(
                    onTap: () => cubit.cycleMeta(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.nostr,
                        borderRadius: AppRadii.br999,
                        border: Border.all(
                          color: context.colors.paper,
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.shuffle,
                        size: 13,
                        color: context.colors.paper,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          AppInput(
            controller: displayNameController,
            icon: LucideIcons.pencil,
            label: "Display name",
            hintText: "Your reading alias",
            onChanged: (val) => cubit.updateDisplayName(val),
            trailing: displayNameController.text.isNotEmpty
                ? BouncingInteractiveWidget(
                    onTap: () {
                      displayNameController.clear();
                      cubit.updateDisplayName('');
                    },
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: context.colors.slate,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          ObBanner(
            icon: LucideIcons.info,
            title: "Optional",
            description:
                "You can change your name and picture anytime from your profile. Skip freely — no pressure.",
            backgroundColor: context.colors.skyTint,
            iconColor: context.colors.sky,
            borderColor: context.colors.sky.withValues(alpha: 0.2),
          ),
        ],
      ],
    );
  }
}
