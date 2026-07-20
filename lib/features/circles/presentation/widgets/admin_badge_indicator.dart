import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';

class AdminBadgeCubit extends Cubit<bool> {
  AdminBadgeCubit(this.circleDirId) : super(false) {
    _init();
  }

  final String circleDirId;
  final _watchUnread = getIt<WatchUnreadAdminActionsUseCase>();
  final _getMyNpub = getIt<GetMyNpubUseCase>();

  Future<void> _init() async {
    final npub = await _getMyNpub();
    if (npub == null || npub.isEmpty) return;

    _watchUnread(npub, circleDirId).listen((hasUnread) {
      if (!isClosed) emit(hasUnread);
    });
  }
}

class AdminBadgeIndicator extends StatelessWidget {
  const AdminBadgeIndicator({
    super.key,
    required this.circleDirId,
    required this.child,
    this.bottom = -2,
    this.right = -2,
    this.top,
    this.left,
    this.color = const Color(0xFFF04438),
  });

  final String circleDirId;
  final Widget child;
  final double? bottom;
  final double? right;
  final double? top;
  final double? left;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBadgeCubit(circleDirId),
      child: BlocBuilder<AdminBadgeCubit, bool>(
        builder: (context, hasAdminActions) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (hasAdminActions)
                Positioned(
                  right: right,
                  bottom: bottom,
                  top: top,
                  left: left,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
