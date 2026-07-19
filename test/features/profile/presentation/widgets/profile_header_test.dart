import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';
import 'package:zapbook/core/presentation/widgets/app_profile_avatar.dart';
import 'package:zapbook/core/presentation/widgets/app_shimmer.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_header.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_share_sheet.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

void main() {
  const profile = UserProfile(
    npub: 'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqabcd',
    displayName: 'Ada Reader',
    picture: '',
    lightningAddress: 'ada@getalby.com',
    satsEarned: 0,
    dayStreak: 0,
    booksRead: 0,
    milestones: 0,
  );

  late MockProfileCubit profileCubit;

  setUp(() {
    profileCubit = MockProfileCubit();
    when(() => profileCubit.state).thenReturn(const ProfileLoaded(profile));
    when(() => profileCubit.copy(any())).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: BlocProvider<ProfileCubit>.value(
          value: profileCubit,
          child: const ProfileHeader(),
        ),
      ),
    );
  }

  testWidgets('renders name, short npub and tap indicator', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Ada Reader'), findsOneWidget);
    expect(find.text(profile.npub.toNpubShort()), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    expect(find.byIcon(LucideIcons.edit2), findsOneWidget);
  });

  testWidgets('shows shimmer placeholder while loading', (tester) async {
    when(() => profileCubit.state).thenReturn(const ProfileLoading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(AppShimmer), findsOneWidget);
    expect(find.text('Ada Reader'), findsNothing);
  });

  testWidgets('tapping name opens ProfileShareSheet', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Ada Reader'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileShareSheet), findsOneWidget);
  });

  testWidgets('tapping avatar opens ProfileShareSheet', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byType(AppProfileAvatar));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileShareSheet), findsOneWidget);
  });

  testWidgets('tapping copy icon copies npub and shows toast', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(LucideIcons.copy));
    await tester.pump();

    verify(() => profileCubit.copy(profile.npub)).called(1);
    expect(find.text('npub copied'), findsOneWidget);
    expect(find.byType(ProfileShareSheet), findsNothing);
  });
}
