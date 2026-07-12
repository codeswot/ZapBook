import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/features/book_reader/data/reading_progress_local_store.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

void main() {
  late ReadingProgressLocalStore repository;
  late MockSharedPreferences mockPrefs;
  late MockIdentityLocalDataSource mockIdentity;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockIdentity = MockIdentityLocalDataSource();

    when(() => mockIdentity.readNpub()).thenAnswer((_) async => 'npub1');

    repository = ReadingProgressLocalStore(mockPrefs, mockIdentity);
  });

  test('saveSnapshot saves reading progress to SharedPreferences', () async {
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

    final state = ReadingState(
      wpm: 250,
      completedPages: {1, 2},
      visitedPages: {1, 2, 3},
      partials: {
        3: const PagePartial(engagedMs: 100, scrollSamples: 2, skimSamples: 1),
      },
      wordsRead: 1000,
      pointsBanked: 5,
      milestonesReached: 1,
      sessionEngagedMs: 5000,
      currentPage: 3,
      bookCompleted: false,
      open: null,
    );

    await repository.saveSnapshot('book1', state, scrollOffset: 15.5);

    final captures = verify(
      () => mockPrefs.setString(captureAny(), captureAny()),
    ).captured;
    expect(captures.length, 2);
    final key = captures[0] as String;
    final value = captures[1] as String;

    expect(key, 'reading_progress_npub1_book1');
    final json = jsonDecode(value) as Map<String, dynamic>;
    expect(json['_scroll_offset'], 15.5);
    expect(json['wpm'], 250);
  });

  test('loadSnapshot loads reading progress from SharedPreferences', () async {
    final stateJson = {
      'wpm': 250.0,
      'completed_pages': [1, 2],
      'visited_pages': [1, 2, 3],
      'partials': {
        '3': {'engaged_ms': 100, 'scroll_samples': 2, 'skim_samples': 1},
      },
      'words_read': 1000,
      'points_banked': 5,
      'milestones_reached': 1,
      'session_engaged_ms': 5000,
      'current_page': 3,
      'book_completed': false,
      '_scroll_offset': 15.5,
    };

    when(
      () => mockPrefs.getString('reading_progress_npub1_book1'),
    ).thenReturn(jsonEncode(stateJson));

    final result = await repository.loadSnapshot('book1');
    expect(result, isNotNull);
    expect(result!.scrollOffset, 15.5);
    expect(result.state.wpm, 250);
    expect(result.state.completedPages, {1, 2});
    expect(result.state.wordsRead, 1000);
  });
}
