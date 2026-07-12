import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/core/services/file_picker_service.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/app_info_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/zap_support_service.dart';
import 'package:zapbook/features/profile/domain/entities/user_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/load_profile.dart';
import 'package:zapbook/features/profile/domain/usecases/sign_out.dart';
import 'package:zapbook/features/profile/domain/usecases/update_profile.dart';
import 'package:zapbook/features/profile/presentation/bloc/profile_cubit.dart';

class MockLoadProfile extends Mock implements LoadProfile {}

class MockUpdateProfile extends Mock implements UpdateProfile {}

class MockSignOut extends Mock implements SignOut {}

class MockClipboardService extends Mock implements ClipboardService {}

class MockNwcService extends Mock implements NwcService {}

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockFilePickerService extends Mock implements FilePickerService {}

class MockKeyPackageService extends Mock implements KeyPackageService {}

class MockAppInfoService extends Mock implements AppInfoService {}

class MockZapSupportService extends Mock implements ZapSupportService {}

void main() {
  late MockLoadProfile loadProfile;
  late MockUpdateProfile updateProfile;
  late MockSignOut signOut;
  late MockClipboardService clipboardService;
  late MockNwcService nwcService;
  late MockIdentityLocalDataSource identityLocalDataSource;
  late MockFilePickerService filePickerService;
  late MockKeyPackageService keyPackageService;
  late MockAppInfoService appInfoService;
  late MockZapSupportService zapSupportService;

  const tProfile = UserProfile(
    npub: 'npub',
    displayName: 'Test',
    picture: '',
    lightningAddress: '',
    satsEarned: 0,
    dayStreak: 0,
    booksRead: 0,
    milestones: 0,
  );

  setUp(() {
    loadProfile = MockLoadProfile();
    updateProfile = MockUpdateProfile();
    signOut = MockSignOut();
    clipboardService = MockClipboardService();
    nwcService = MockNwcService();
    identityLocalDataSource = MockIdentityLocalDataSource();
    filePickerService = MockFilePickerService();
    keyPackageService = MockKeyPackageService();
    appInfoService = MockAppInfoService();
    zapSupportService = MockZapSupportService();

    when(() => loadProfile()).thenAnswer((_) async => tProfile);
    when(() => nwcService.walletName).thenReturn('Alby');
    when(
      () => nwcService.connectionString,
    ).thenReturn('nostr+walletconnect://...');
    when(() => nwcService.isConnected).thenReturn(true);
    when(() => appInfoService.version).thenReturn('1.0.0');
    when(() => zapSupportService.percent).thenReturn(10);
  });

  ProfileCubit buildCubit() => ProfileCubit(
    loadProfile,
    updateProfile,
    signOut,
    clipboardService,
    nwcService,
    identityLocalDataSource,
    filePickerService,
    keyPackageService,
    appInfoService,
    zapSupportService,
  );

  group('ProfileCubit', () {
    blocTest<ProfileCubit, ProfileState>(
      'loads profile on init',
      build: buildCubit,
      expect: () => [const ProfileLoaded(tProfile, nwcWalletName: 'Alby')],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits ProfileError when load fails',
      setUp: () {
        when(() => loadProfile()).thenThrow(Exception('Failed to load'));
      },
      build: buildCubit,
      act: (cubit) async => cubit.load(),
      expect: () => [
        const ProfileLoading(),
        const ProfileError('Exception: Failed to load'),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'updateProfile updates and reloads',
      setUp: () {
        when(() => loadProfile()).thenAnswer((_) async => tProfile);
      },
      build: buildCubit,
      seed: () => const ProfileLoaded(tProfile, nwcWalletName: 'Alby'),
      act: (cubit) async {
        when(
          () => updateProfile(displayName: 'New', lud16: 'lud', picture: 'pic'),
        ).thenAnswer((_) async {});
        await cubit.updateProfile(
          displayName: 'New',
          lud16: 'lud',
          picture: 'pic',
        );
      },
      expect: () => [
        const ProfileLoading(),
        const ProfileLoaded(tProfile, nwcWalletName: 'Alby'),
      ],
      verify: (_) {
        verify(
          () => updateProfile(displayName: 'New', lud16: 'lud', picture: 'pic'),
        ).called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'connectNwc connects and refreshes NWC',
      build: buildCubit,
      seed: () => const ProfileLoaded(tProfile, nwcWalletName: null),
      act: (cubit) async {
        when(() => nwcService.connect('uri')).thenAnswer((_) async {});
        await cubit.connectNwc('uri');
      },
      expect: () => [const ProfileLoaded(tProfile, nwcWalletName: 'Alby')],
      verify: (_) {
        verify(() => nwcService.connect('uri')).called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'disconnectNwc disconnects and refreshes NWC',
      build: buildCubit,
      seed: () => const ProfileLoaded(tProfile, nwcWalletName: 'Alby'),
      act: (cubit) async {
        when(() => nwcService.disconnect()).thenAnswer((_) async {});
        when(() => nwcService.walletName).thenReturn(null);
        await cubit.disconnectNwc();
      },
      expect: () => [const ProfileLoaded(tProfile, nwcWalletName: null)],
      verify: (_) {
        verify(() => nwcService.disconnect()).called(1);
      },
    );

    test('getters return correctly from services', () {
      final cubit = buildCubit();
      expect(cubit.nwcConnectionString, 'nostr+walletconnect://...');
      expect(cubit.isNwcConnected, true);
      expect(cubit.appVersion, '1.0.0');
      expect(cubit.supportPercent, 10);
      expect(cubit.supportPercentOptions, [0, 3, 5, 10, 15, 20, 50, 100]);
      expect(cubit.donationRecipient, 'zapbook@blink.sv'); // default
    });

    test('pickImage returns encoded image', () async {
      when(
        () => filePickerService.pickImage(),
      ).thenAnswer((_) async => Uint8List.fromList([0x00, 0x01]));
      final cubit = buildCubit();
      final res = await cubit.pickImage();
      expect(res, 'data:image/png;base64,AAE=');
    });

    test('pickImage returns empty on null', () async {
      when(() => filePickerService.pickImage()).thenAnswer((_) async => null);
      final cubit = buildCubit();
      final res = await cubit.pickImage();
      expect(res, '');
    });

    test('readNsec', () async {
      when(
        () => identityLocalDataSource.readNsec(),
      ).thenAnswer((_) async => 'nsec1...');
      final cubit = buildCubit();
      expect(await cubit.readNsec(), 'nsec1...');
    });

    test('copy', () async {
      when(() => clipboardService.copy('text')).thenAnswer((_) async {});
      final cubit = buildCubit();
      await cubit.copy('text');
      verify(() => clipboardService.copy('text')).called(1);
    });

    test('rotateKeyPackage', () async {
      when(() => keyPackageService.forceRotate()).thenAnswer((_) async => true);
      final cubit = buildCubit();
      expect(await cubit.rotateKeyPackage(), true);
    });

    test('signOut', () async {
      when(() => signOut()).thenAnswer((_) async {});
      final cubit = buildCubit();
      await cubit.signOut();
      verify(() => signOut()).called(1);
    });

    test('setSupportPercent', () async {
      when(() => zapSupportService.setPercent(5)).thenAnswer((_) async {});
      final cubit = buildCubit();
      await cubit.setSupportPercent(5);
      verify(() => zapSupportService.setPercent(5)).called(1);
    });
  });
}
