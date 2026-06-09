import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class ReadingStatsService {
  String? _dirPath;

  int _booksRead = 0;
  int _satsEarned = 0;
  final _milestoneDates = <String>{};

  int get booksRead => _booksRead;
  int get satsEarned => _satsEarned;
  Set<String> get milestoneDates => Set.unmodifiable(_milestoneDates);

  int get streak {
    if (_milestoneDates.isEmpty) return 0;
    final sorted = _milestoneDates.toList()..sort();
    final today = _today();
    final yesterday = _dayOffset(-1);

    final lastDate = sorted.last;
    if (lastDate != today && lastDate != yesterday) return 0;

    var count = 0;
    var expected = lastDate;
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i] == expected) {
        count++;
        expected = _dayBefore(expected);
      } else {
        break;
      }
    }
    return count;
  }

  Future<String> _dir() async {
    if (_dirPath != null) return _dirPath!;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/stats');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dirPath = dir.path;
    return dir.path;
  }

  Future<void> load() async {
    final dir = await _dir();
    final file = File('$dir/reading_stats.json');
    if (!file.existsSync()) return;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _booksRead = (json['books_read'] as num?)?.toInt() ?? 0;
      _satsEarned = (json['sats_earned'] as num?)?.toInt() ?? 0;
      _milestoneDates
        ..clear()
        ..addAll((json['milestone_dates'] as List?)?.cast<String>() ?? []);
    } on Object {
      return;
    }
  }

  Future<void> _save() async {
    final dir = await _dir();
    await File('$dir/reading_stats.json').writeAsString(jsonEncode({
      'books_read': _booksRead,
      'sats_earned': _satsEarned,
      'milestone_dates': _milestoneDates.toList(),
    }));
  }

  void recordMilestone() {
    _milestoneDates.add(_today());
    unawaited(_save());
  }

  void recordBookCompleted() {
    _booksRead++;
    unawaited(_save());
  }

  void addSats(int amount) {
    _satsEarned += amount;
    unawaited(_save());
  }

  String _today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);

  String _dayOffset(int offset) {
    final d = DateTime.now().toUtc().add(Duration(days: offset));
    return d.toIso8601String().substring(0, 10);
  }

  String _dayBefore(String date) {
    final d = DateTime.parse('${date}T00:00:00Z').subtract(const Duration(days: 1));
    return d.toIso8601String().substring(0, 10);
  }
}
