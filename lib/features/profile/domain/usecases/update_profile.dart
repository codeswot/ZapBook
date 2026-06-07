import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';

@injectable
final class UpdateProfile {
  const UpdateProfile(this._remote, this._session);

  final ProfileRemoteDataSource _remote;
  final NostrSession _session;

  Future<void> call({
    String? displayName,
    String? lud16,
    String? picture,
  }) async {
    if (!_session.isLoggedIn) return;
    await _remote.publish(
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
  }
}
