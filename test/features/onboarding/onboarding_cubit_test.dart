import 'package:flutter_test/flutter_test.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/identity/nostr_session.dart';
import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/core/services/key_package_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart';
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';

class MockClipboardService extends Mock implements ClipboardService {}

class MockNostrService extends Mock implements NostrService {}

class MockIdentityRepository extends Mock implements IdentityRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockNostrSession extends Mock implements NostrSession {}

class MockKeyPackageService extends Mock implements KeyPackageService {}

void main() {
  late MockClipboardService clipboard;
  late MockNostrService nostr;
  late MockIdentityRepository identityRepo;
  late MockOnboardingRepository onboardingRepo;
  late MockNostrSession session;
  late MockKeyPackageService keyPackage;
  late GenerateIdentity generateIdentity;
  late ImportIdentity importIdentity;
  late CompleteOnboarding completeOnboarding;

  const keypair = NostrKeypair(
    npub: 'npub1example',
    nsec: 'nsec1example',
    pubkeyHex: 'deadbeef',
  );

  setUp(() {
    clipboard = MockClipboardService();
    nostr = MockNostrService();
    identityRepo = MockIdentityRepository();
    onboardingRepo = MockOnboardingRepository();
    session = MockNostrSession();
    keyPackage = MockKeyPackageService();

    generateIdentity = GenerateIdentity(identityRepo);
    importIdentity = ImportIdentity(identityRepo);
    completeOnboarding = CompleteOnboarding(
      identityRepo,
      onboardingRepo,
      session,
    );

    when(() => identityRepo.generate()).thenAnswer((_) async => keypair);
    when(
      () => identityRepo.persist(
        npub: any(named: 'npub'),
        nsec: any(named: 'nsec'),
      ),
    ).thenAnswer((_) async {});
    when(() => session.login()).thenAnswer((_) async => true);
    when(() => onboardingRepo.complete()).thenAnswer((_) async {});
    when(() => nostr.isLoggedIn).thenReturn(false);
  });

  OnboardingCubit buildCubit() => OnboardingCubit(
    clipboard,
    nostr,
    generateIdentity,
    importIdentity,
    completeOnboarding,
    keyPackage,
  );

  Future<OnboardingCubit> buildReadyCubit() async {
    final cubit = buildCubit();
    if (cubit.state.generatedNpub.isEmpty) {
      await cubit.stream.firstWhere((s) => s.generatedNpub.isNotEmpty);
    }
    return cubit;
  }

  test('publishes key package on completion and clears failure flag', () async {
    when(() => keyPackage.ensurePublished()).thenAnswer((_) async => true);
    final cubit = await buildReadyCubit();

    final ok = await cubit.completeOnboarding(publish: false);

    expect(ok, isTrue);
    expect(cubit.state.isComplete, isTrue);
    expect(cubit.state.keyPackagePublishFailed, isFalse);
    verify(() => keyPackage.ensurePublished()).called(1);
    await cubit.close();
  });

  test('flags failure when key package publish fails', () async {
    when(() => keyPackage.ensurePublished()).thenAnswer((_) async => false);
    final cubit = await buildReadyCubit();

    final ok = await cubit.completeOnboarding(publish: false);

    expect(ok, isTrue);
    expect(cubit.state.isComplete, isTrue);
    expect(cubit.state.keyPackagePublishFailed, isTrue);
    await cubit.close();
  });

  test('does not complete or publish when identity is missing', () async {
    when(
      () => identityRepo.generate(),
    ).thenAnswer((_) async => const NostrKeypair(npub: '', pubkeyHex: ''));
    final cubit = buildCubit();

    final ok = await cubit.completeOnboarding();

    expect(ok, isFalse);
    verifyNever(() => keyPackage.ensurePublished());
    await cubit.close();
  });
}
