import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/features/ai_model/presentation/cubit/ai_model_cubit.dart';
import 'package:zapbook/features/ai_model/presentation/widgets/ai_download_banner.dart';
import 'package:zapbook/features/ai_model/presentation/widgets/ai_missing_banner.dart';
import 'package:zapbook/features/heads_up/domain/models/heads_up_message.dart';
import 'package:zapbook/features/heads_up/presentation/cubit/heads_up_cubit.dart';

class AiModelHeadsUpBridge extends StatefulWidget {
  final Widget child;

  const AiModelHeadsUpBridge({super.key, required this.child});

  @override
  State<AiModelHeadsUpBridge> createState() => _AiModelHeadsUpBridgeState();
}

class _AiModelHeadsUpBridgeState extends State<AiModelHeadsUpBridge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncAiBanner(context.read<AiModelCubit>().state);
      }
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiModelCubit, AiModelState>(
      listener: (context, state) => _syncAiBanner(state),
      child: widget.child,
    );
  }
}
