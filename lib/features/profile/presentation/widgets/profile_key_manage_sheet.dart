import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/core/presentation/theme/app_radii.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_button.dart';
import 'package:zapbook/core/presentation/widgets/app_sheet.dart';
import 'package:zapbook/core/presentation/widgets/app_toast.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';

class ProfileKeyManageSheet extends StatefulWidget {
  final String npub;
  final String? nsec;
  final String? signerPackage;
  final ProfileCubit cubit;

  const ProfileKeyManageSheet({
    super.key,
    required this.npub,
    required this.nsec,
    required this.cubit,
    this.signerPackage,
  });

  bool get isExternal => signerPackage != null && signerPackage!.isNotEmpty;

  @override
  State<ProfileKeyManageSheet> createState() => _ProfileKeyManageSheetState();

  static Future<void> show(
    BuildContext context, {
    required String npub,
    required String? nsec,
    required ProfileCubit cubit,
    String? signerPackage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileKeyManageSheet(
        npub: npub,
        nsec: nsec,
        cubit: cubit,
        signerPackage: signerPackage,
      ),
    );
  }
}

class _ProfileKeyManageSheetState extends State<ProfileKeyManageSheet> {
  bool _nsecRevealed = false;
  late final _cubit = widget.cubit;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Keys',
              style: context.typography.displayM.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isExternal
                  ? 'Your secret key is held by your external signer app.'
                  : 'Never share your secret key with anyone.',
              style: context.typography.bodyL.copyWith(
                color: context.colors.slate,
              ),
            ),
            const SizedBox(height: 20),
            _KeyBlock(
              label: 'Public Key (npub)',
              displayValue: widget.npub.toNpubReadable(),
              onTap: () {
                _cubit.copy(widget.npub);
                context.toast.showInfo(
                  'Public Key (npub) copied to clipboard',
                  rootNavigator: true,
                );
              },
            ),
            const SizedBox(height: 12),
            if (widget.isExternal)
              _ExternalSignerBlock(package: widget.signerPackage!)
            else ...[
              _KeyBlock(
                label: 'Secret Key (nsec)',
                displayValue: _nsecRevealed ? (widget.nsec ?? '') : _masked,
                onTap: () {
                  final nsec = widget.nsec;
                  if (nsec == null) return;
                  _cubit.copy(nsec);
                  context.toast.showInfo(
                    'Secret Key (nsec) copied to clipboard',
                    rootNavigator: true,
                  );
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _nsecRevealed ? 'Hide secret key' : 'Reveal secret key',
                fullWidth: true,
                variant: AppButtonVariant.tonal,
                icon: _nsecRevealed ? LucideIcons.eyeOff : LucideIcons.eye,
                onTap: () => setState(() => _nsecRevealed = !_nsecRevealed),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String get _masked => 'nsec1•••••••••••••••••••••••••••••••••••••••••••';
}

class _ExternalSignerBlock extends StatelessWidget {
  final String package;

  const _ExternalSignerBlock({required this.package});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Secret Key (nsec)',
          style: context.typography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.slate,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.paper2,
            borderRadius: AppRadii.br10,
            border: Border.all(color: context.colors.hairline),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 18,
                color: context.colors.bitcoin,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Managed by external signer',
                      style: context.typography.bodyL.copyWith(
                        color: context.colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.bodyS.copyWith(
                        color: context.colors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyBlock extends StatelessWidget {
  final String label;
  final String displayValue;
  final VoidCallback onTap;

  const _KeyBlock({
    required this.label,
    required this.displayValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.slate,
          ),
        ),
        const SizedBox(height: 6),
        BouncingInteractiveWidget(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.paper2,
              borderRadius: AppRadii.br10,
              border: Border.all(color: context.colors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue,
                    style: context.typography.mono.copyWith(
                      fontSize: 12,
                      color: context.colors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.copy, size: 15, color: context.colors.slate),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
