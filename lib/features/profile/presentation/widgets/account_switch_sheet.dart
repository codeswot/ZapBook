import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_state.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_input.dart';
import 'package:zapbook/widgets/app_paste_button.dart';
import 'package:zapbook/widgets/app_profile_avatar.dart';
import 'package:zapbook/widgets/app_sheet.dart';
import 'package:zapbook/widgets/app_toast.dart';
import 'package:zapbook/widgets/app_shimmer.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AccountSwitchSheet extends StatelessWidget {
  const AccountSwitchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SwitchAccountCubit>(
      create: (_) => getIt<SwitchAccountCubit>()..load(),
      child: const _Body(),
    );
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colors.transparent,
      builder: (_) => const AccountSwitchSheet(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _nsecController = TextEditingController();
  bool _showAddInput = false;
  bool _wasAdding = false;

  @override
  void dispose() {
    _nsecController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final cubit = context.read<SwitchAccountCubit>();

    return BlocConsumer<SwitchAccountCubit, SwitchAccountState>(
      listener: (context, state) {
        if (state is SwitchAccountError) {
          context.toast.showError(state.message, rootNavigator: true);
          _wasAdding = false;
        } else if (state is SwitchAccountBusy && state.isAdding) {
          _wasAdding = true;
        } else if (state is SwitchAccountLoaded && _wasAdding) {
          _nsecController.clear();
          _showAddInput = false;
          _wasAdding = false;
        }
      },
      builder: (context, state) {
        final accounts = state is SwitchAccountLoaded
            ? state.accounts
            : state is SwitchAccountBusy
            ? state.accounts
            : state is SwitchAccountError
            ? state.accounts
            : <SwitchAccountItem>[];

        final activeNpub = state is SwitchAccountLoaded
            ? state.activeNpub
            : state is SwitchAccountBusy
            ? state.activeNpub
            : state is SwitchAccountError
            ? state.activeNpub
            : '';

        final isLoading = state is SwitchAccountLoading;
        final busyNpub = state is SwitchAccountBusy ? state.busyNpub : null;
        final isAdding = state is SwitchAccountBusy && state.isAdding;

        return AppSheet(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Switch account',
                        style: typography.displayM.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                    ),
                    BouncingInteractiveWidget(
                      onTap: () {
                        setState(() {
                          _showAddInput = !_showAddInput;
                        });
                      },
                      child: Icon(
                        _showAddInput
                            ? LucideIcons.chevronUp
                            : LucideIcons.userPlus,
                        color: colors.bitcoin,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and switch between identities.',
                  style: typography.body.copyWith(color: colors.slate),
                ),
                const SizedBox(height: 18),
                if (_showAddInput) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppInput(
                          label: 'Import by nsec',
                          hintText: 'nsec1…',
                          icon: LucideIcons.key,
                          controller: _nsecController,
                          onChanged: (_) => setState(() {}),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_nsecController.text.isNotEmpty)
                                BouncingInteractiveWidget(
                                  onTap: () {
                                    _nsecController.clear();
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: colors.slate2,
                                    ),
                                  ),
                                ),
                              if (isAdding)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                BouncingInteractiveWidget(
                                  onTap: _nsecController.text.trim().isEmpty
                                      ? null
                                      : () => cubit.importAccount(
                                          _nsecController.text.trim(),
                                        ),
                                  child: Text(
                                    'Import',
                                    style: typography.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _nsecController.text.trim().isEmpty
                                          ? colors.slate2
                                          : colors.bitcoin,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppPasteButton(
                        onPaste: (text) {
                          _nsecController.text = text;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (isLoading)
                  const _AccountShimmerList()
                else ...[
                  for (final item in accounts) ...[
                    BouncingInteractiveWidget(
                      onTap: () => cubit.switchAccount(item.npub),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item.npub == activeNpub
                              ? colors.paper2
                              : colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.npub == activeNpub
                                ? colors.hairline2
                                : colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppProfileAvatar(url: item.picture, size: 36),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typography.bodyL.copyWith(
                                      color: colors.ink,
                                      fontWeight: item.npub == activeNpub
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    item.npub.toNpubShort(),
                                    style: typography.bodyS.copyWith(
                                      color: colors.slate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (busyNpub == item.npub)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else if (item.npub == activeNpub)
                              Icon(
                                LucideIcons.check,
                                color: colors.positive,
                                size: 20,
                              )
                            else
                              BouncingInteractiveWidget(
                                onTap: () => cubit.removeAccount(item.npub),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    LucideIcons.trash2,
                                    color: colors.tomato,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountShimmerList extends StatelessWidget {
  const _AccountShimmerList();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(3, (index) => const _AccountItemSkeleton()),
      ),
    );
  }
}

class _AccountItemSkeleton extends StatelessWidget {
  const _AccountItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          const AppShimmerBox(width: 36, height: 36, shape: BoxShape.circle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppShimmerBox(width: 100, height: 14),
                SizedBox(height: 6),
                AppShimmerBox(width: 160, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
