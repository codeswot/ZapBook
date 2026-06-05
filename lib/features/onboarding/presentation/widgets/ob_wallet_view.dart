import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_paste_button.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/theme/app_radii.dart';
import 'package:zapbook/widgets/app_icon_button.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_banner.dart';
import 'package:zapbook/features/onboarding/presentation/widgets/ob_step_intro.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class ObWalletView extends StatelessWidget {
  final OnboardingState state;
  final OnboardingCubit cubit;
  final TextEditingController lnAddressController;

  const ObWalletView({
    super.key,
    required this.state,
    required this.cubit,
    required this.lnAddressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ObStepIntro(
          icon: LucideIcons.wallet,
          accentColor: context.colors.bitcoin,
          accentDim: context.colors.bitcoinTint,
          accentLine: context.colors.bitcoinTint2,
          over: "Step 2 · Wallet",
          title: "Where your sats land",
          description:
              "Connect a Lightning address so the sats you earn reading can be zapped straight to you.",
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AppInput(
                controller: lnAddressController,
                icon: LucideIcons.wallet,
                label: "Lightning address (lud16)",
                hintText: "wren@walletofsatoshi.com",
                onChanged: (val) => cubit.updateLightningAddress(val),
                trailing: lnAddressController.text.isNotEmpty
                    ? AppIconButton(
                        icon: LucideIcons.x,
                        onTap: () {
                          lnAddressController.clear();
                          cubit.updateLightningAddress('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            ObPasteButton(onTap: () => cubit.pasteLightningAddress()),
          ],
        ),
        const SizedBox(height: 14),
        ObBanner(
          icon: LucideIcons.info,
          title: "No wallet yet?",
          description:
              "Any Lightning address works — Wallet of Satoshi, Alby, Phoenix, and more. You can always add it later from settings.",
          backgroundColor: context.colors.skyTint,
          iconColor: context.colors.sky,
          borderColor: context.colors.sky.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 18),
        Text(
          "Popular wallets",
          style: context.typography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.slate,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: ["Wallet of Satoshi", "Alby", "Phoenix"].map((p) {
            return BouncingInteractiveWidget(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.paper2,
                  borderRadius: AppRadii.br12,
                  border: Border.all(color: context.colors.hairline),
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: context.typography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.slate,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
