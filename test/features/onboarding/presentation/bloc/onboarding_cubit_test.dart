import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/domain/usecases/clipboard_usecases.dart';
import 'package:zapbook/features/onboarding/domain/usecases/connect_external_signer.dart';
import 'package:zapbook/features/onboarding/domain/usecases/fetch_existing_profile.dart';
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart';
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';

class MockCopyTextUseCase extends Mock implements CopyTextUseCase {}

class MockPasteTextUseCase extends Mock implements PasteTextUseCase {}

class MockFetchExistingProfileUseCase extends Mock
    implements FetchExistingProfileUseCase {}

class MockGenerateIdentity extends Mock implements GenerateIdentity {}

class MockImportIdentity extends Mock implements ImportIdentity {}

class MockCompleteOnboarding extends Mock implements CompleteOnboarding {}

class MockConnectExternalSigner extends Mock implements ConnectExternalSigner {}

void main() {
  late MockCopyTextUseCase copyText;
  late MockPasteTextUseCase pasteText;
  late MockFetchExistingProfileUseCase fetchExistingProfile;
  late MockGenerateIdentity generateIdentity;
  late MockImportIdentity importIdentity;
  late MockCompleteOnboarding completeOnboarding;
  late MockConnectExternalSigner connectExternalSigner;

  setUp(() {
    copyText = MockCopyTextUseCase();
    pasteText = MockPasteTextUseCase();
    fetchExistingProfile = MockFetchExistingProfileUseCase();
    generateIdentity = MockGenerateIdentity();
    importIdentity = MockImportIdentity();
    completeOnboarding = MockCompleteOnboarding();
    connectExternalSigner = MockConnectExternalSigner();

    when(() => generateIdentity()).thenAnswer(
      (_) async => const NostrKeypair(
        npub: 'npub_test',
        nsec: 'nsec_test',
        pubkeyHex: 'hex_test',
      ),
    );
    when(() => fetchExistingProfile(any())).thenAnswer((_) async => null);
  });

  OnboardingCubit buildCubit() {
    return OnboardingCubit(
      copyText,
      pasteText,
      fetchExistingProfile,
      generateIdentity,
      importIdentity,
      completeOnboarding,
      connectExternalSigner,
    );
  }

  group('OnboardingCubit', () {
    test('initial state generates keys', () async {
      final cubit = buildCubit();
      expect(cubit.state.step, OnboardingStep.welcome);

      // Wait for generation to complete
      await Future.delayed(Duration.zero);
      expect(cubit.state.generatedNpub, 'npub_test');
      expect(cubit.state.generatedNsec, 'nsec_test');
      expect(cubit.state.isBusy, false);
      verify(() => generateIdentity()).called(1);
    });

    test('nextStep progresses through steps', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero); // wait for generation

      cubit.nextStep();
      expect(cubit.state.step, OnboardingStep.identity);

      cubit.nextStep();
      expect(cubit.state.step, OnboardingStep.wallet);

      cubit.nextStep();
      expect(cubit.state.step, OnboardingStep.profile);
      expect(cubit.state.displayName, isNotEmpty);
    });

    test('previousStep regresses through steps', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);
      cubit.selectStep(OnboardingStep.profile);

      cubit.previousStep();
      expect(cubit.state.step, OnboardingStep.wallet);

      cubit.previousStep();
      expect(cubit.state.step, OnboardingStep.identity);

      cubit.previousStep();
      expect(cubit.state.step, OnboardingStep.welcome);
    });

    test('toggleIdentityMode updates mode and generates keys if new', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      cubit.toggleIdentityMode(false);
      expect(cubit.state.isGeneratingNew, false);

      cubit.toggleIdentityMode(true);
      expect(cubit.state.isGeneratingNew, true);
      // Wait for generation
      await Future.delayed(Duration.zero);
      expect(cubit.state.generatedNpub, 'npub_test');
    });

    test('importNsec successful', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      when(() => importIdentity('my_secret')).thenAnswer(
        (_) async => const NostrKeypair(
          npub: 'npub_imported',
          nsec: 'my_secret',
          pubkeyHex: 'hex_imported',
        ),
      );
      final success = await cubit.importNsec('my_secret');

      expect(success, true);
      expect(cubit.state.importedNsec, 'my_secret');
      expect(cubit.state.generatedNpub, 'npub_imported');
      expect(cubit.state.generatedNsec, 'my_secret');
      expect(cubit.state.isBusy, false);
    });

    test('importNsec fails on empty input', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      final success = await cubit.importNsec('   ');

      expect(success, false);
      expect(cubit.state.error, 'Please enter your secret key');
    });

    test('update fields', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      cubit.updateImportedNsec('imported');
      expect(cubit.state.importedNsec, 'imported');

      cubit.updateLightningAddress('lud16');
      expect(cubit.state.lightningAddress, 'lud16');

      cubit.updateDisplayName('name');
      expect(cubit.state.displayName, 'name');
    });

    test('copy and paste keys', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      when(() => copyText(any())).thenAnswer((_) async {});
      when(() => pasteText()).thenAnswer((_) async => 'pasted_nsec');

      await cubit.copyKeys();
      await cubit.pasteNsec();

      expect(cubit.state.importedNsec, 'pasted_nsec');
      verify(() => copyText(any())).called(1);
      verify(() => pasteText()).called(1);
    });

    test('pasteLightningAddress', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      when(() => pasteText()).thenAnswer((_) async => 'pasted_lud');
      await cubit.pasteLightningAddress();

      expect(cubit.state.lightningAddress, 'pasted_lud');
    });

    test('completeOnboarding success', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      when(
        () => completeOnboarding(
          npub: any(named: 'npub'),
          nsec: any(named: 'nsec'),
          signerPackage: any(named: 'signerPackage'),
          displayName: any(named: 'displayName'),
          lud16: any(named: 'lud16'),
          picture: any(named: 'picture'),
        ),
      ).thenAnswer((_) async {});

      final success = await cubit.completeOnboarding(publish: false);

      expect(success, true);
      expect(cubit.state.isBusy, true);
      verify(
        () => completeOnboarding(
          npub: 'npub_test',
          nsec: 'nsec_test',
          signerPackage: null,
          displayName: null,
          lud16: null,
          picture: null,
        ),
      ).called(1);
    });

    test('completeOnboarding with publish', () async {
      final cubit = buildCubit();
      await Future.delayed(Duration.zero);

      cubit.updateDisplayName('Name');
      cubit.updateLightningAddress('user@example.com');
      // mock picture? No way to update picture right now directly except cycleMeta or fetch
      // We will just verify Name and Lud16

      when(
        () => completeOnboarding(
          npub: any(named: 'npub'),
          nsec: any(named: 'nsec'),
          signerPackage: any(named: 'signerPackage'),
          displayName: any(named: 'displayName'),
          lud16: any(named: 'lud16'),
          picture: any(named: 'picture'),
        ),
      ).thenAnswer((_) async {});

      final success = await cubit.completeOnboarding(publish: true);

      expect(success, true);
      expect(cubit.state.isBusy, true);
      verify(
        () => completeOnboarding(
          npub: 'npub_test',
          nsec: 'nsec_test',
          signerPackage: null,
          displayName: 'Name',
          lud16: 'user@example.com',
          picture: null,
        ),
      ).called(1);
    });
  });
}
