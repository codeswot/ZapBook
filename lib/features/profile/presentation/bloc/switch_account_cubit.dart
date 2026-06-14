import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/services/profile_meta_generator.dart';
import 'package:zapbook/core/session/session_manager.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_state.dart';

@injectable
class SwitchAccountCubit extends Cubit<SwitchAccountState> {
  SwitchAccountCubit(this._identityLocal, this._identityRepo, this._remote)
    : super(const SwitchAccountLoading());

  final IdentityLocalDataSource _identityLocal;
  final IdentityRepository _identityRepo;
  final ProfileRemoteDataSource _remote;
  final _log = logging.Logger('SwitchAccountCubit');

  Future<void> load() async {
    emit(const SwitchAccountLoading());
    try {
      final npubs = await _identityLocal.listNpubs();
      final activeNpub = await _identityLocal.readNpub() ?? '';

      final accounts = <SwitchAccountItem>[];
      for (final npub in npubs) {
        final fallback = ProfileMetaGenerator.generate(seed: npub);
        accounts.add(
          SwitchAccountItem(
            npub: npub,
            name: fallback.displayName,
            picture: fallback.avatar,
          ),
        );
      }

      emit(SwitchAccountLoaded(accounts: accounts, activeNpub: activeNpub));

      for (var i = 0; i < accounts.length; i++) {
        final item = accounts[i];
        try {
          final meta = await _remote.fetchMetadata(npub: item.npub);
          if (meta != null) {
            final fetchedName = meta.displayName ?? meta.name;
            final currentLoaded = _currentAccounts;
            final updatedAccounts = currentLoaded.map((a) {
              if (a.npub == item.npub) {
                return a.copyWith(
                  name: (fetchedName != null && fetchedName.isNotEmpty)
                      ? fetchedName
                      : a.name,
                  picture: (meta.picture != null && meta.picture!.isNotEmpty)
                      ? meta.picture
                      : a.picture,
                );
              }
              return a;
            }).toList();

            final active = _currentActiveNpub;
            emit(
              SwitchAccountLoaded(
                accounts: updatedAccounts,
                activeNpub: active,
              ),
            );
          }
        } catch (_) {}
      }
    } on Object catch (e, stack) {
      _log.warning('Load accounts failed', e, stack);
      emit(const SwitchAccountLoaded(accounts: [], activeNpub: ''));
    }
  }

  Future<void> switchAccount(String npub) async {
    final accounts = _currentAccounts;
    final active = _currentActiveNpub;
    if (npub == active) return;

    emit(
      SwitchAccountBusy(accounts: accounts, activeNpub: active, busyNpub: npub),
    );
    try {
      await _identityLocal.setActive(npub);
      await reloadSession();
    } on Object catch (e, stack) {
      _log.warning('Switch account failed', e, stack);
      emit(SwitchAccountLoaded(accounts: accounts, activeNpub: active));
    }
  }

  Future<void> removeAccount(String npub) async {
    final accounts = _currentAccounts;
    final active = _currentActiveNpub;
    if (npub == active) return;

    emit(
      SwitchAccountBusy(accounts: accounts, activeNpub: active, busyNpub: npub),
    );
    try {
      await _identityLocal.removeAccount(npub);
      await load();
    } on Object catch (e, stack) {
      _log.warning('Remove account failed', e, stack);
      emit(SwitchAccountLoaded(accounts: accounts, activeNpub: active));
    }
  }

  Future<bool> importAccount(String nsec) async {
    final trimmed = nsec.trim();
    if (trimmed.isEmpty) return false;

    final accounts = _currentAccounts;
    final active = _currentActiveNpub;

    emit(
      SwitchAccountBusy(accounts: accounts, activeNpub: active, isAdding: true),
    );
    try {
      final isValid = await _identityRepo.validateNsec(trimmed);
      if (!isValid) {
        throw const FormatException('Invalid secret key');
      }

      final keypair = await _identityRepo.importFromNsec(trimmed);
      await _identityRepo.persist(npub: keypair.npub, nsec: keypair.nsec!);

      await reloadSession();
      return true;
    } on Object catch (e, stack) {
      _log.warning('Import account failed', e, stack);
      final errorMsg = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('FormatException: ', '');
      emit(SwitchAccountError.from(state, 'Import failed: $errorMsg'));
      return false;
    }
  }

  List<SwitchAccountItem> get _currentAccounts {
    final s = state;
    if (s is SwitchAccountLoaded) return s.accounts;
    if (s is SwitchAccountBusy) return s.accounts;
    if (s is SwitchAccountError) return s.accounts;
    return const [];
  }

  String get _currentActiveNpub {
    final s = state;
    if (s is SwitchAccountLoaded) return s.activeNpub;
    if (s is SwitchAccountBusy) return s.activeNpub;
    if (s is SwitchAccountError) return s.activeNpub;
    return '';
  }
}
