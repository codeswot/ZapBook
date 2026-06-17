import 'dart:convert';

import 'package:ndk/ndk.dart';

extension Nip01EventMarmot on Nip01Event {
  String toMarmotJson() => jsonEncode({
    'id': id,
    'pubkey': pubKey,
    'created_at': createdAt,
    'kind': kind,
    'tags': tags,
    'content': content,
    'sig': sig,
  });
}
