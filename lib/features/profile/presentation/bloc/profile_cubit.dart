import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/features/profile/domain/repositories/profile_repository.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_state.dart';

export 'package:zapbook/features/profile/presentation/bloc/profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, this._clipboard)
    : super(const ProfileLoading()) {
    load();
  }

  final ProfileRepository _repository;
  final ClipboardService _clipboard;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      emit(ProfileLoaded(await _repository.load()));
    } on Object catch (error) {
      emit(ProfileError('$error'));
    }
  }

  Future<void> copy(String value) => _clipboard.copy(value);

  Future<void> signOut() => _repository.signOut();
}
