import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging show Logger;

import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/features/circles/domain/usecases/circles_usecases.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';

@injectable
class ShareCircleCubit extends Cubit<ShareCircleState> {
  ShareCircleCubit(
    this._getFriendsUseCase,
    this._getCircleBookUseCase,
    this._getExistingMemberNpubsUseCase,
    this._shareUseCase,
    this._getMyNpubUseCase,
  ) : super(const ShareCircleLoading());

  final GetFriendsUseCase _getFriendsUseCase;
  final GetCircleBookUseCase _getCircleBookUseCase;
  final GetExistingMemberNpubsUseCase _getExistingMemberNpubsUseCase;
  final ShareCircleBookUseCase _shareUseCase;
  final GetMyNpubUseCase _getMyNpubUseCase;

  final _log = logging.Logger('ShareCircleCubit');

  bool isValidNpub(String value) {
    if (value.isEmpty) return false;
    final npubRegex = RegExp(r'^npub1[02-9ac-hj-np-z]{58}$');
    return npubRegex.hasMatch(value);
  }

  Future<void> load(String circleBookId) async {
    final friends = await _getFriendsUseCase();

    final book = await _getCircleBookUseCase(circleBookId);
    var existingMembers = <String>{};

    if (book != null && book.id.isNotEmpty) {
      existingMembers = await _getExistingMemberNpubsUseCase(circleBookId);
    }

    emit(
      ShareCircleLoaded(
        friends: friends,
        selectedNpubs: const [],
        existingMembers: existingMembers,
      ),
    );
  }

  void toggleNpub(String npub) {
    final s = state;
    if (s is! ShareCircleLoaded) return;

    final current = List<String>.from(s.selectedNpubs);
    if (current.contains(npub)) {
      current.remove(npub);
    } else {
      current.add(npub);
    }

    emit(
      ShareCircleLoaded(
        friends: s.friends,
        selectedNpubs: current,
        existingMembers: s.existingMembers,
      ),
    );
  }

  Future<void> addNpub(String npub) async {
    final s = state;
    if (s is! ShareCircleLoaded) return;

    emit(
      ShareCircleBusy(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
        adding: true,
      ),
    );

    final current = List<String>.from(s.selectedNpubs);
    if (!current.contains(npub)) {
      current.add(npub);
    }

    emit(
      ShareCircleLoaded(
        friends: s.friends,
        selectedNpubs: current,
        existingMembers: s.existingMembers,
      ),
    );
  }

  Future<List<ShareSkip>> share(String circleBookId) async {
    final s = state;
    if (s is! ShareCircleLoaded) return [];
    if (s.selectedNpubs.isEmpty) return [];

    final myNpub = await _getMyNpubUseCase();
    if (myNpub == null) return [];

    emit(
      ShareCircleBusy(
        friends: s.friends,
        selectedNpubs: s.selectedNpubs,
        existingMembers: s.existingMembers,
        sharing: true,
      ),
    );

    try {
      final skips = await _shareUseCase(
        circleBookId: circleBookId,
        npubs: s.selectedNpubs,
        myNpub: myNpub,
      );

      if (!isClosed) {
        emit(
          ShareCircleLoaded(
            friends: s.friends,
            selectedNpubs: const [],
            existingMembers: s.existingMembers,
            shareResult: skips,
          ),
        );
      }

      return skips;
    } catch (e, stack) {
      _log.severe('Failed to share circle book', e, stack);

      if (!isClosed) {
        emit(
          ShareCircleLoaded(
            friends: s.friends,
            selectedNpubs: s.selectedNpubs,
            existingMembers: s.existingMembers,
          ),
        );
      }
      rethrow;
    }
  }
}
