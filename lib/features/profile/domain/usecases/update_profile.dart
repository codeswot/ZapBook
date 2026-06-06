import 'package:injectable/injectable.dart';

import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';

@injectable
final class UpdateProfile {
  const UpdateProfile(this._remote, this._identityLocal);

  final ProfileRemoteDataSource _remote;
  final IdentityLocalDataSource _identityLocal;

  Future<void> call({
    required String npub,
    String? displayName,
    String? lud16,
    String? picture,
  }) async {
    final nsec = await _identityLocal.readNsec();
    if (nsec == null || nsec.isEmpty) return;
    await _remote.publish(
      npub: npub,
      nsec: nsec,
      displayName: displayName,
      lud16: lud16,
      picture: picture,
    );
  }
}
