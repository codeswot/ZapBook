import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/domain/contact.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_cubit.dart';
import 'package:zapbook/features/circles/presentation/bloc/share_circle_state.dart';
import 'package:zapbook/core/presentation/widgets/share_circle_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';

class MockShareCircleCubit extends Mock implements ShareCircleCubit {}

void main() {
  late MockShareCircleCubit shareCircleCubit;

  final testBook = CircleBook(
    id: 'b1',
    nostrGroudId: 'g1',
    circleDirId: 'd1',
    title: 'Test Book',
    author: 'Author',
    sourceFormat: BookSourceFormat.epub,
    pageCount: 10,
    chapterCount: 2,
    zbfPath: 'path/to/zbf',
    needsAiProcessing: false,
    zbfVersion: '1',
    createdAt: DateTime.now(),
    addedAt: DateTime.now(),
  );

  setUp(() async {
    await getIt.reset();
    shareCircleCubit = MockShareCircleCubit();
    getIt.registerSingleton<ShareCircleCubit>(shareCircleCubit);

    when(() => shareCircleCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => shareCircleCubit.load(any())).thenAnswer((_) async {});
    when(() => shareCircleCubit.isValidNpub(any())).thenReturn(true);
    when(() => shareCircleCubit.close()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ShareCircleSheet.show(context, testBook),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('ShareCircleSheet', () {
    testWidgets('renders loading state', (tester) async {
      when(() => shareCircleCubit.state).thenReturn(const ShareCircleLoading());

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(find.byType(ShareCircleSheet), findsOneWidget);
    });

    testWidgets('renders loaded state with friends', (tester) async {
      final contact = Contact(
        npub: 'npub1test12345678901234567890123456789012345678901234567890',
        displayName: 'Bob',
      );

      when(() => shareCircleCubit.state).thenReturn(
        ShareCircleLoaded(
          friends: [contact],
          selectedNpubs: [],
          existingMembers: {},
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('renders empty friends state', (tester) async {
      when(() => shareCircleCubit.state).thenReturn(
        const ShareCircleLoaded(
          friends: [],
          selectedNpubs: [],
          existingMembers: {},
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        find.text('No contacts yet. Paste an npub to add your first friend.'),
        findsOneWidget,
      );
    });
  });
}
