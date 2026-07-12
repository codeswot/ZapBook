import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';

@lazySingleton
class ReadingProgressLocalStore {
  ReadingProgressLocalStore(this._prefs, this._identity);

  final SharedPreferences _prefs;
  final IdentityLocalDataSource _identity;

  String _key(String npub, String circleDirId) =>
      'reading_progress_${npub}_$circleDirId';

  Future<void> saveSnapshot(
    String circleDirId,
    ReadingState state, {
    double? scrollOffset,
  }) async {
    final npub = await _identity.readNpub();
    if (npub == null) return;

    final json = _stateToJson(state);
    if (scrollOffset != null) {
      json['_scroll_offset'] = scrollOffset;
    }
    await _prefs.setString(_key(npub, circleDirId), jsonEncode(json));
  }

  Future<({ReadingState state, double? scrollOffset})?> loadSnapshot(
    String circleDirId,
  ) async {
    final npub = await _identity.readNpub();
    if (npub == null) return null;

    final str = _prefs.getString(_key(npub, circleDirId));
    if (str == null) return null;

    try {
      final json = jsonDecode(str) as Map<String, dynamic>;
      final scrollOffset = (json['_scroll_offset'] as num?)?.toDouble();
      return (state: _stateFromJson(json), scrollOffset: scrollOffset);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _stateToJson(ReadingState state) => {
    'wpm': state.wpm,
    'completed_pages': state.completedPages.toList(),
    'visited_pages': state.visitedPages.toList(),
    'partials': {
      for (final entry in state.partials.entries)
        entry.key.toString(): {
          'engaged_ms': entry.value.engagedMs,
          'scroll_samples': entry.value.scrollSamples,
          'skim_samples': entry.value.skimSamples,
        },
    },
    'words_read': state.wordsRead,
    'points_banked': state.pointsBanked,
    'milestones_reached': state.milestonesReached,
    'session_engaged_ms': state.sessionEngagedMs,
    'current_page': state.currentPage,
    'book_completed': state.bookCompleted,
  };

  ReadingState _stateFromJson(Map<String, dynamic> json) {
    final partialsJson = json['partials'] as Map<String, dynamic>? ?? {};
    final partials = <int, PagePartial>{};
    for (final entry in partialsJson.entries) {
      final v = entry.value as Map<String, dynamic>;
      partials[int.parse(entry.key)] = PagePartial(
        engagedMs: v['engaged_ms'] as int,
        scrollSamples: v['scroll_samples'] as int,
        skimSamples: v['skim_samples'] as int,
      );
    }

    return ReadingState(
      wpm: (json['wpm'] as num?)?.toDouble() ?? 240,
      completedPages:
          (json['completed_pages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      visitedPages:
          (json['visited_pages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      partials: partials,
      wordsRead: (json['words_read'] as num?)?.toInt() ?? 0,
      pointsBanked: (json['points_banked'] as num?)?.toInt() ?? 0,
      milestonesReached: (json['milestones_reached'] as num?)?.toInt() ?? 0,
      sessionEngagedMs: (json['session_engaged_ms'] as num?)?.toInt() ?? 0,
      currentPage: json['current_page'] as int?,
      bookCompleted: json['book_completed'] as bool? ?? false,
      open: null,
    );
  }
}
