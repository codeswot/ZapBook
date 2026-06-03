import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_paste_button.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_icon_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_banner.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_step_intro.dart';
import 'package:zapbook/widgets/app_toast.dart';

class ObIdentityView extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;
  final TextEditingController nsecController;

  const ObIdentityView({
    super.key,
    required this.state,
    required this.cubit,
    required this.nsecController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ObStepIntro(
          icon: LucideIcons.key,
          accentColor: context.colors.plum,
          accentDim: context.colors.plumTint,
          accentLine: context.colors.plumTint2,
          over: "Step 1 · Identity",
          title: "Your Nostr identity",
          description:
              "Your account is a key that belongs to you — no email, no password, no company holding it.",
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: context.colors.paper2,
            borderRadius: AppRadii.br14,
            border: Border.all(color: context.colors.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => cubit.toggleIdentityMode(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: state.isGeneratingNew
                          ? context.colors.bgElev
                          : context.colors.transparent,
                      borderRadius: AppRadii.br10,
                      border: Border.all(
                        color: state.isGeneratingNew
                            ? context.colors.hairline2
                            : context.colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Generate new",
                      style: context.typography.body.copyWith(
                        fontWeight: state.isGeneratingNew
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: state.isGeneratingNew
                            ? context.colors.ink
                            : context.colors.slate,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BouncingInteractiveWidget(
                  onTap: () => cubit.toggleIdentityMode(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !state.isGeneratingNew
                          ? context.colors.bgElev
                          : context.colors.transparent,
                      borderRadius: AppRadii.br10,
                      border: Border.all(
                        color: !state.isGeneratingNew
                            ? context.colors.hairline2
                            : context.colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Import nsec",
                      style: context.typography.body.copyWith(
                        fontWeight: !state.isGeneratingNew
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: !state.isGeneratingNew
                            ? context.colors.ink
                            : context.colors.slate,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (state.isGeneratingNew) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.paper2,
              borderRadius: AppRadii.br18,
              border: Border.all(color: context.colors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your public key",
                      style: context.typography.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.plum,
                        letterSpacing: 0.05,
                      ),
                    ),
                    Row(
                      children: [
                        BouncingInteractiveWidget(
                          onTap: () => cubit.regenerateKeys(),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: context.colors.paper3,
                              borderRadius: AppRadii.br10,
                              border: Border.all(
                                color: context.colors.hairline,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.refreshCw,
                              size: 15,
                              color: context.colors.slate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BouncingInteractiveWidget(
                          onTap: () async {
                            await cubit.copyKeys();
                            if (context.mounted) {
                              context.toast.showSuccess("Keys copied to clipboard");
                            }
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: context.colors.paper3,
                              borderRadius: AppRadii.br10,
                              border: Border.all(
                                color: context.colors.hairline,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.copy,
                              size: 15,
                              color: context.colors.slate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.generatedNpub,
                  style: context.typography.mono.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                    color: context.colors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ObBanner(
            icon: LucideIcons.alertTriangle,
            title: "Save your secret key",
            description:
                "Write down or store your nsec somewhere safe. If you lose it, nobody — including us — can get your account back.",
            backgroundColor: context.colors.tomatoTint,
            iconColor: context.colors.tomato,
            borderColor: context.colors.tomato.withValues(alpha: 0.2),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppInput(
                  controller: nsecController,
                  icon: LucideIcons.key,
                  label: "Secret Key (nsec)",
                  hintText: "nsec1...",
                  onChanged: (val) => cubit.updateImportedNsec(val),
                  trailing: nsecController.text.isNotEmpty
                      ? AppIconButton(
                          icon: LucideIcons.x,
                          onTap: () {
                            nsecController.clear();
                            cubit.updateImportedNsec('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
               ObPasteButton(
                onTap: () async {
                  final text = await cubit.pasteNsec();
                  if (text != null) {
                    nsecController.text = text;
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
