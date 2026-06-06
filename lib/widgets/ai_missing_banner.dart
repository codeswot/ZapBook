import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/services/device_capability_service.dart';
import 'package:zapbook/core/services/ai_service.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/widgets/app_banner.dart';
import 'package:zapbook/core/cubit/ai_model_cubit.dart';
import 'package:zapbook/widgets/bouncing_interactive_widget.dart';

class AiMissingBanner extends StatelessWidget {
  const AiMissingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiModelCubit, AiModelState>(
      builder: (context, state) {
        final cubit = context.read<AiModelCubit>();
        final capability = state.capability;

        return AppBanner(
          backgroundColor: context.colors.coralTint,
          leading: Icon(
            LucideIcons.alertCircle,
            color: context.colors.tomato,
            size: 16,
          ),
          title: BouncingInteractiveWidget(
            onTap: () {
              final url = capability?.modelUrl;
              final hash = capability?.expectedHash;
              if (url != null && hash != null) {
                cubit.startDownload(url, hash);
              }
            },
            child: Text(
              'AI model missing. Tap to set it up.',
              style: context.typography.bodyS.copyWith(
                color: context.colors.tomato,
                decoration: TextDecoration.underline,
                decorationColor: context.colors.tomato,
              ),
            ),
          ),
          trailing: BouncingInteractiveWidget(
            onTap: cubit.dismissBanner,
            child: Icon(LucideIcons.x, color: context.colors.slate, size: 20),
          ),
        );
      },
    );
  }
}
