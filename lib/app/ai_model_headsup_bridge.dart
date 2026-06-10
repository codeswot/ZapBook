import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/services/ai_model_service.dart';
import 'package:zapbook/core/cubit/ai_model_cubit.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/widgets/ai_download_banner.dart';
import 'package:zapbook/widgets/ai_missing_banner.dart';
import 'package:zapbook/core/domain/heads_up_message.dart';
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart';

class AiModelHeadsUpBridge extends StatefulWidget {
  final Widget child;

  const AiModelHeadsUpBridge({super.key, required this.child});

  @override
  State<AiModelHeadsUpBridge> createState() => _AiModelHeadsUpBridgeState();
}

class _AiModelHeadsUpBridgeState extends State<AiModelHeadsUpBridge> {
  static const _lastShownKey = 'ai_heads_up_last_shown';
  static const _twoDays = Duration(days: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndSync(context.read<AiModelCubit>().state);
    });
  }

  void _checkAndSync(AiModelState aiState) {
    final prefs = getIt<SharedPreferences>();
    final lastShown = prefs.getInt(_lastShownKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastShown != null && now - lastShown < _twoDays.inMilliseconds) {
      return;
    }
    _syncAiBanner(aiState);
  }

  void _syncAiBanner(AiModelState aiState) {
    final headsUpCubit = context.read<HeadsUpCubit>();
    if (aiState.bannerDismissed) {
      headsUpCubit.dismissBanner('ai_model');
      return;
    }

    switch (aiState.status) {
      case AiModelStatus.notSet:
        headsUpCubit.showBanner(
          HeadsUpMessage(id: 'ai_model', child: const AiMissingBanner()),
        );
        break;
      case AiModelStatus.downloading:
      case AiModelStatus.paused:
      case AiModelStatus.verifying:
        headsUpCubit.showBanner(
          HeadsUpMessage(id: 'ai_model', child: const AiDownloadBanner()),
        );
        break;
      case AiModelStatus.ready:
      case AiModelStatus.skipped:
        headsUpCubit.dismissBanner('ai_model');
        break;
    }

    getIt<SharedPreferences>().setInt(
      _lastShownKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiModelCubit, AiModelState>(
      listener: (context, state) => _checkAndSync(state),
      child: widget.child,
    );
  }
}
