import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging show Logger;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/identity/active_account.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/features/circles/domain/entities/share_skip.dart';
import 'package:zapbook/features/circles/domain/usecases/share_circle_book.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';

@injectable
class ShareCircleCubit extends Cubit<ShareCircleState> {
  ShareCircleCubit(
    this._contactService,
    this._circleStore,
    this._marmot,
    this._shareUseCase,
  ) : super(const ShareCircleLoading());

  final ContactService _contactService;
  final CircleStoreService _circleStore;
  final Marmot _marmot;
  final ShareCircleBookUseCase _shareUseCase;
  final _log = logging.Logger('ShareCircleCubit');
  bool isValidNpub(String value) {
    try {
      MarmotIdentity.pubkeyHexFromNpub(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> load(String circleBookId) async {
    final friends = await _contactService.friends.first;

    final book = _circleStore.currentCircles
        .where((b) => b.id == circleBookId)
        .firstOrNull;
    final existingMembers = <String>{};

    if (book != null && book.id.isNotEmpty) {
      try {
        final members = await _marmot.getMembers(book.id);
        for (final member in members) {
          try {
            final npub = Nip19.encodePubKey(member.pubkeyHex);
            existingMembers.add(npub);
          } catch (_) {}
        }
      } catch (e, stack) {
        _log.warning('Failed to load group members', e, stack);
      }
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

    final myNpub = ActiveAccount.currentNpub;
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

      emit(
        ShareCircleLoaded(
          friends: s.friends,
          selectedNpubs: const [],
          existingMembers: s.existingMembers,
          shareResult: skips,
        ),
      );

      return skips;
    } catch (e, stack) {
      _log.severe('Failed to share circle book', e, stack);

      emit(
        ShareCircleLoaded(
          friends: s.friends,
          selectedNpubs: s.selectedNpubs,
          existingMembers: s.existingMembers,
        ),
      );
      rethrow;
    }
  }
}
