import 'dart:collection';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

@lazySingleton
class DecodedMessageCache {
  static const _maxEntries = 5000;

  final _cache = HashMap<String, _Entry>();
  final _order = LinkedList<_Entry>();

  Map<String, dynamic>? get(MarmotMessage message) {
    final raw = message.payloadJson;
    if (raw == null || raw.isEmpty) return null;

    final existing = _cache[message.id];
    if (existing != null) {
      existing.unlink();
      _order.addFirst(existing);
      return existing.value;
    }

    Map<String, dynamic>? decoded;
    try {
      final result = jsonDecode(raw);
      decoded = result is Map<String, dynamic> ? result : null;
    } on Object {
      decoded = null;
    }

    final entry = _Entry(message.id, decoded);
    _cache[message.id] = entry;
    _order.addFirst(entry);

    while (_cache.length > _maxEntries) {
      final last = _order.last;
      last.unlink();
      _cache.remove(last.id);
    }

    return decoded;
  }

  void clear() {
    _cache.clear();
    _order.clear();
  }
}

final class _Entry extends LinkedListEntry<_Entry> {
  _Entry(this.id, this.value);

  final String id;
  final Map<String, dynamic>? value;
}
