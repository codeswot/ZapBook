import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/presentation/widgets/app_loading_list.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/bouncing_interactive_widget.dart';
import 'package:zapbook/features/profile/presentation/bloc/friends_cubit.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class NpubPreview extends StatefulWidget {
  final String npub;
  final VoidCallback onAdd;
  final bool isAdding;

  const NpubPreview({
    super.key,
    required this.npub,
    required this.onAdd,
    required this.isAdding,
  });

  @override
  State<NpubPreview> createState() => _NpubPreviewState();
}

class _NpubPreviewState extends State<NpubPreview> {
  Future<Contact>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  @override
  void didUpdateWidget(NpubPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.npub != widget.npub) {
      _fetch();
    }
  }

  void _fetch() {
    setState(() {
      _future = context.read<FriendsCubit>().resolveNpub(widget.npub);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return FutureBuilder<Contact>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _future == null) {
          return const AppLoadingList(itemCount: 1);
        }
        final contact = snapshot.data;
        if (contact == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add new contact',
              style: typography.body.copyWith(color: colors.slate),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppProfileAvatar(url: contact.picture ?? '', size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contact.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.bodyL.copyWith(color: colors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.shortNpub,
                        style: typography.bodyS.copyWith(color: colors.slate),
                      ),
                    ],
                  ),
                ),
                if (widget.isAdding)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  BouncingInteractiveWidget(
                    onTap: widget.onAdd,
                    child: Icon(
                      LucideIcons.userPlus,
                      size: 20,
                      color: colors.bitcoin,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
