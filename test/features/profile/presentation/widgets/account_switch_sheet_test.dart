import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/di/injection.dart';
import 'package:zapbook/core/presentation/widgets/app_input.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_state.dart';
import 'package:zapbook/features/profile/presentation/widgets/account_switch_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

class MockSwitchAccountCubit extends Mock implements SwitchAccountCubit {}

void main() {
  late MockSwitchAccountCubit mockCubit;

  setUp(() {
    mockCubit = MockSwitchAccountCubit();
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCubit.close()).thenAnswer((_) async {});
    getIt.allowReassignment = true;
    getIt.registerFactory<SwitchAccountCubit>(() => mockCubit);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestApp() {
    return MaterialApp(
      theme: lightTheme,
      home: const Scaffold(body: AccountSwitchSheet()),
    );
  }

  group('AccountSwitchSheet', () {
    testWidgets('renders loading state initially', (tester) async {
      when(() => mockCubit.state).thenReturn(const SwitchAccountLoading());
      when(() => mockCubit.load()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());

      expect(find.text('Switch account'), findsOneWidget);
    });

    testWidgets('renders loaded state with accounts', (tester) async {
      final item = SwitchAccountItem(
        npub: 'npub1testtesttesttesttesttesttesttesttesttesttesttesttestt',
        name: 'Test User',
        picture: '',
      );

      when(() => mockCubit.state).thenReturn(
        SwitchAccountLoaded(
          accounts: [item],
          activeNpub:
              'npub1testtesttesttesttesttesttesttesttesttesttesttesttestt',
        ),
      );
      when(() => mockCubit.load()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());

      expect(find.text('Test User'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('can toggle add input', (tester) async {
      when(
        () => mockCubit.state,
      ).thenReturn(const SwitchAccountLoaded(accounts: [], activeNpub: ''));
      when(() => mockCubit.load()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());

      expect(find.byType(AppInput), findsNothing);

      await tester.tap(find.byIcon(LucideIcons.userPlus));
      await tester.pump();

      expect(find.byType(AppInput), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronUp), findsOneWidget);
    });

    testWidgets('can tap import with input', (tester) async {
      when(
        () => mockCubit.state,
      ).thenReturn(const SwitchAccountLoaded(accounts: [], activeNpub: ''));
      when(() => mockCubit.load()).thenAnswer((_) async {});
      when(() => mockCubit.importAccount(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.byIcon(LucideIcons.userPlus));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'nsec1abc');
      await tester.pump();

      await tester.tap(find.text('Import'));
      await tester.pump();

      verify(() => mockCubit.importAccount('nsec1abc')).called(1);
    });

    testWidgets('can delete inactive account', (tester) async {
      final item1 = SwitchAccountItem(
        npub: 'npub1active',
        name: 'Active User',
        picture: '',
      );
      final item2 = SwitchAccountItem(
        npub: 'npub1inactive',
        name: 'Inactive User',
        picture: '',
      );

      when(() => mockCubit.state).thenReturn(
        SwitchAccountLoaded(
          accounts: [item1, item2],
          activeNpub: 'npub1active',
        ),
      );
      when(() => mockCubit.load()).thenAnswer((_) async {});
      when(() => mockCubit.removeAccount(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());

      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pump();

      verify(() => mockCubit.removeAccount('npub1inactive')).called(1);
    });

    testWidgets('can switch account', (tester) async {
      final item1 = SwitchAccountItem(
        npub: 'npub1active',
        name: 'Active User',
        picture: '',
      );
      final item2 = SwitchAccountItem(
        npub: 'npub1inactive',
        name: 'Inactive User',
        picture: '',
      );

      when(() => mockCubit.state).thenReturn(
        SwitchAccountLoaded(
          accounts: [item1, item2],
          activeNpub: 'npub1active',
        ),
      );
      when(() => mockCubit.load()).thenAnswer((_) async {});
      when(() => mockCubit.switchAccount(any())).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Inactive User'));
      await tester.pump();

      verify(() => mockCubit.switchAccount('npub1inactive')).called(1);
    });
  });
}
