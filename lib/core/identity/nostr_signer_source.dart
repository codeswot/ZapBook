import 'package:ndk/ndk.dart';

abstract interface class NostrSignerSource {
  Future<EventSigner?> resolve();
}
