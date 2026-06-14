import 'package:flutter_test/flutter_test.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:zapbook/core/services/clipboard_service.dart';
import 'package:zapbook/core/services/nostr_service.dart';
import 'package:zapbook/core/session/session_reloader.dart';
import 'package:zapbook/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:zapbook/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:zapbook/features/onboarding/domain/usecases/generate_identity.dart';
import 'package:zapbook/features/onboarding/domain/usecases/import_identity.dart';
import 'package:zapbook/features/onboarding/presentation/bloc/onboarding_cubit.dart';

class MockClipboardService extends Mock implements ClipboardService {}

class MockNostrService extends Mock implements NostrService {}

class MockIdentityRepository extends Mock implements IdentityRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockSessionReloader extends Mock implements SessionReloader {}

void main() {
  late MockClipboardService clipboard;
  late MockNostrService nostr;
  late MockIdentityRepository identityRepo;
  late MockOnboardingRepository onboardingRepo;
  late MockSessionReloader reloader;
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
    reloader = MockSessionReloader();

    generateIdentity = GenerateIdentity(identityRepo);
    importIdentity = ImportIdentity(identityRepo);
    completeOnboarding = CompleteOnboarding(
      identityRepo,
      onboardingRepo,
      reloader,
    );

    when(() => identityRepo.generate()).thenAnswer((_) async => keypair);
    when(
      () => identityRepo.persist(
        npub: any(named: 'npub'),
        nsec: any(named: 'nsec'),
      ),
    ).thenAnswer((_) async {});
    when(() => onboardingRepo.complete()).thenAnswer((_) async {});
    when(
      () => onboardingRepo.stashPendingProfile(
        displayName: any(named: 'displayName'),
        lud16: any(named: 'lud16'),
        picture: any(named: 'picture'),
      ),
    ).thenAnswer((_) async {});
    when(() => reloader.reload()).thenAnswer((_) async {});
  });

  OnboardingCubit buildCubit() => OnboardingCubit(
    clipboard,
    nostr,
    generateIdentity,
    importIdentity,
    completeOnboarding,
  );

  Future<OnboardingCubit> buildReadyCubit() async {
    final cubit = buildCubit();
    if (cubit.state.generatedNpub.isEmpty) {
      await cubit.stream.firstWhere((s) => s.generatedNpub.isNotEmpty);
    }
    return cubit;
  }

  test('persists, completes and reloads the session on completion', () async {
    final cubit = await buildReadyCubit();

    final ok = await cubit.completeOnboarding(publish: false);

    expect(ok, isTrue);
    verify(
      () => identityRepo.persist(
        npub: keypair.npub,
        nsec: any(named: 'nsec'),
      ),
    ).called(1);
    verify(() => onboardingRepo.complete()).called(1);
    verify(() => reloader.reload()).called(1);
    await cubit.close();
  });

  test('does not complete or reload when identity is missing', () async {
    when(
      () => identityRepo.generate(),
    ).thenAnswer((_) async => const NostrKeypair(npub: '', pubkeyHex: ''));
    final cubit = buildCubit();

    final ok = await cubit.completeOnboarding();

    expect(ok, isFalse);
    verifyNever(() => reloader.reload());
    await cubit.close();
  });
}
