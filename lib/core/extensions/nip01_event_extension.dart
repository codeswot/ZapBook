import 'dart:convert';

import 'package:ndk/ndk.dart';

extension Nip01EventExtension on Nip01Event {
  String toJsonString() => jsonEncode({
        'id': id,
        'pubkey': pubKey,
        'created_at': createdAt,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig,
      });
}
