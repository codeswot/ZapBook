import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zapbook/core/extensions/string_extension.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/presentation/widgets/profile_share_sheet.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

void main() {
  final profile = UserProfile(
    npub: 'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqabcd',
    displayName: 'Ada Reader',
    picture: 'test.jpg',
    lightningAddress: 'ada@getalby.com',
    satsEarned: 0,
    dayStreak: 0,
    booksRead: 0,
    milestones: 0,
  );

  testWidgets('ProfileShareSheet renders avatar, name, QR code and npub', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: ProfileShareSheet(profile: profile, onCopy: (_) async {}),
        ),
      ),
    );

    expect(find.text('Ada Reader'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(profile.npub.toNpubShort()), findsOneWidget);
  });

  testWidgets('tapping copy invokes onCopy and shows success toast', (
    tester,
  ) async {
    String? copied;

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: ProfileShareSheet(
            profile: profile,
            onCopy: (value) async => copied = value,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.byIcon(LucideIcons.copy));
    await tester.tap(find.byIcon(LucideIcons.copy));
    await tester.pump();

    expect(copied, profile.npub);
    expect(find.text('npub copied'), findsOneWidget);
  });
}
