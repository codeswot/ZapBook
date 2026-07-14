import 'package:zapbook/core/domain/entities/cheers_activity_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_view.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_cubit.dart';
import 'package:zapbook/features/cheers/presentation/bloc/cheers_state.dart';
import 'package:zapbook/features/cheers/domain/entities/cheers_activity.dart';
import 'package:zapbook/theme/app_theme.dart';
import 'package:zapbook/features/cheers/presentation/widgets/cheers_activity_card.dart';
import 'package:get_it/get_it.dart';
import 'package:zapbook/core/data/database/app_database.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/services/nostr_service.dart';

class MockCheersCubit extends Mock implements CheersCubit {}

class MockNostrService extends Mock implements NostrService {}

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MockCheersCubit cheersCubit;
  late MockNostrService nostrService;
  late MockAppDatabase appDatabase;

  setUp(() async {
    await GetIt.I.reset();
    cheersCubit = MockCheersCubit();
    nostrService = MockNostrService();
    appDatabase = MockAppDatabase();

    GetIt.I.registerSingleton<NostrService>(nostrService);
    GetIt.I.registerSingleton<AppDatabase>(appDatabase);

    when(() => nostrService.pubkey).thenReturn('npub1');
    when(
      () => nostrService.getMetadata(any()),
    ).thenAnswer((_) async => Metadata(pubKey: 'npub1', name: 'Alice'));

    when(() => cheersCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget() {
    return BlocProvider<CheersCubit>.value(
      value: cheersCubit,
      child: MaterialApp(
        theme: lightTheme,
        home: const Scaffold(body: CheersView()),
      ),
    );
  }

  group('CheersView', () {
    testWidgets('renders loading state', (tester) async {
      when(() => cheersCubit.state).thenReturn(const CheersLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('All'), findsOneWidget); // Filter chip
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
      ); // Using shimmer probably
    });

    testWidgets('renders loaded state with activities', (tester) async {
      final activity = CheersActivity(
        id: '1',
        groupId: 'g1',
        actorNpub: 'npub2',
        otherPartyNpub: '',
        targetId: '',
        targetDescription: 'description',
        timestamp: DateTime.now(),
        type: CheersActivityType.zap,
        isUnread: false,
        isMine: false,
        otherPartyName: '',
        otherPartyPicture: '',
        actorName: 'Alice',
        actorPicture: '',
        bookId: 'cb1',
        zapAmount: 100,
      );

      when(
        () => cheersCubit.state,
      ).thenReturn(CheersLoaded(activities: [activity], activeFilter: 'All'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CheersActivityCard), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      when(
        () => cheersCubit.state,
      ).thenReturn(const CheersLoaded(activities: [], activeFilter: 'All'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No cheers found'), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      when(() => cheersCubit.state).thenReturn(const CheersError('Test Error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Error'), findsOneWidget);
    });
  });
}
