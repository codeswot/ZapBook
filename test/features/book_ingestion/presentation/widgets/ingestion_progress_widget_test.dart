import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/book_ingestion/domain/enums/ingestion_stage.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_bloc.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_event.dart';
import 'package:zapbook/features/book_ingestion/presentation/bloc/ingestion_state.dart';
import 'package:zapbook/features/book_ingestion/presentation/widgets/ingestion_progress_widget.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/zbf/zbf.dart';

class _MockIngestionBloc extends MockBloc<IngestionEvent, IngestionState>
    implements IngestionBloc {}

void main() {
  late _MockIngestionBloc bloc;

  setUp(() => bloc = _MockIngestionBloc());

  Future<void> pumpWithState(WidgetTester tester, IngestionState state) async {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream<IngestionState>.value(state), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: BlocProvider<IngestionBloc>.value(
            value: bloc,
            child: const IngestionProgressWidget(),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the idle prompt', (tester) async {
    await pumpWithState(tester, const IngestionIdle());
    expect(find.text('Select a book to ingest'), findsOneWidget);
  });

  testWidgets('shows stage label and current item while running', (
    tester,
  ) async {
    await pumpWithState(
      tester,
      const IngestionInProgress(
        stage: IngestionStage.extracting,
        progress: 0.4,
        currentItem: 'Page 4 of 10',
      ),
    );
    expect(find.text('Extracting content'), findsOneWidget);
    expect(find.text('Page 4 of 10'), findsOneWidget);
  });

  testWidgets('shows completion summary', (tester) async {
    await pumpWithState(
      tester,
      IngestionComplete(
        zbfPath: '/tmp/book.zbf',
        manifest: BookManifest(
          id: 'id',
          title: 'Pixels',
          author: 'Author',
          sourceFormat: BookSourceFormat.txt,
          pageCount: 12,
          chapterCount: 3,
          coverAsset: 'cover.png',
          createdAt: DateTime.utc(2026),
          needsAiProcessing: false,
        ),
      ),
    );
    expect(find.textContaining('Pixels'), findsOneWidget);
    expect(find.textContaining('3 chapters'), findsOneWidget);
  });

  testWidgets('shows the failure stage and message', (tester) async {
    await pumpWithState(
      tester,
      const IngestionFailed(
        error: 'broken file',
        failedAt: IngestionStage.extracting,
      ),
    );
    expect(find.textContaining('Failed during'), findsOneWidget);
    expect(find.text('broken file'), findsOneWidget);
  });
}
