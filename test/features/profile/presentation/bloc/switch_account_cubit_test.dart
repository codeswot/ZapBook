import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/identity/identity_repository.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:zapbook/core/session/session_reloader.dart';
import 'package:zapbook/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_state.dart';

class MockIdentityLocalDataSource extends Mock
    implements IdentityLocalDataSource {}

class MockIdentityRepository extends Mock implements IdentityRepository {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockSessionReloader extends Mock implements SessionReloader {}

void main() {
  late MockIdentityLocalDataSource identityLocal;
  late MockIdentityRepository identityRepo;
  late MockProfileRemoteDataSource remote;
  late MockSessionReloader sessionReloader;

  setUp(() {
    identityLocal = MockIdentityLocalDataSource();
    identityRepo = MockIdentityRepository();
    remote = MockProfileRemoteDataSource();
    sessionReloader = MockSessionReloader();
  });

  SwitchAccountCubit createCubit() =>
      SwitchAccountCubit(identityLocal, identityRepo, remote, sessionReloader);

  group('SwitchAccountCubit', () {
    test('initial state is SwitchAccountLoading', () {
      final cubit = createCubit();
      expect(cubit.state, isA<SwitchAccountLoading>());
    });

    test('load populates accounts', () async {
      when(
        () => identityLocal.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1', 'npub2']));
      when(
        () => identityLocal.readNpub(),
      ).thenAnswer((_) => Future.value('npub1'));
      when(
        () => remote.fetchMetadata(npub: any(named: 'npub')),
      ).thenAnswer((_) => Future.value(null));

      final cubit = createCubit();
      await cubit.load();

      expect(cubit.state, isA<SwitchAccountLoaded>());
      final state = cubit.state as SwitchAccountLoaded;
      expect(state.activeNpub, 'npub1');
      expect(state.accounts.length, 2);
    });

    test('switchAccount updates active and reloads session', () async {
      when(
        () => identityLocal.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1', 'npub2']));
      when(
        () => identityLocal.readNpub(),
      ).thenAnswer((_) => Future.value('npub1'));
      when(
        () => remote.fetchMetadata(npub: any(named: 'npub')),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => identityLocal.setActive(any()),
      ).thenAnswer((_) => Future.value());
      when(() => sessionReloader.reload()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      await cubit.switchAccount('npub2');

      verify(() => identityLocal.setActive('npub2')).called(1);
      verify(() => sessionReloader.reload()).called(1);
    });

    test('removeAccount removes and reloads accounts', () async {
      when(
        () => identityLocal.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1', 'npub2']));
      when(
        () => identityLocal.readNpub(),
      ).thenAnswer((_) => Future.value('npub1'));
      when(
        () => remote.fetchMetadata(npub: any(named: 'npub')),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => identityLocal.removeAccount(any()),
      ).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      await cubit.removeAccount('npub2');

      verify(() => identityLocal.removeAccount('npub2')).called(1);
      verify(() => identityLocal.listNpubs()).called(2);
    });

    test('importAccount validates, persists, and reloads session', () async {
      when(
        () => identityLocal.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(
        () => identityLocal.readNpub(),
      ).thenAnswer((_) => Future.value('npub1'));
      when(
        () => remote.fetchMetadata(npub: any(named: 'npub')),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => identityRepo.validateNsec(any()),
      ).thenAnswer((_) => Future.value(true));
      when(() => identityRepo.importFromNsec(any())).thenAnswer(
        (_) => Future.value(
          const NostrKeypair(npub: 'npub2', nsec: 'nsec2', pubkeyHex: ''),
        ),
      );
      when(
        () => identityRepo.persist(
          npub: any(named: 'npub'),
          nsec: any(named: 'nsec'),
        ),
      ).thenAnswer((_) => Future.value());
      when(() => sessionReloader.reload()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.importAccount('nsec2');

      expect(result, isTrue);
      verify(() => identityRepo.validateNsec('nsec2')).called(1);
      verify(() => identityRepo.importFromNsec('nsec2')).called(1);
      verify(
        () => identityRepo.persist(npub: 'npub2', nsec: 'nsec2'),
      ).called(1);
      verify(() => sessionReloader.reload()).called(1);
    });

    test('importAccount returns false on invalid nsec', () async {
      when(
        () => identityLocal.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(
        () => identityLocal.readNpub(),
      ).thenAnswer((_) => Future.value('npub1'));
      when(
        () => remote.fetchMetadata(npub: any(named: 'npub')),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => identityRepo.validateNsec(any()),
      ).thenAnswer((_) => Future.value(false));

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.importAccount('invalid');

      expect(result, isFalse);
      expect(cubit.state, isA<SwitchAccountError>());
    });

    test('importAccount handles exception gracefully', () async {
      when(
        () => identityLocal.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(
        () => identityLocal.readNpub(),
      ).thenAnswer((_) => Future.value('npub1'));
      when(
        () => remote.fetchMetadata(npub: any(named: 'npub')),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => identityRepo.validateNsec(any()),
      ).thenThrow(Exception('Simulated error'));

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.importAccount('invalid');

      expect(result, isFalse);
      expect(cubit.state, isA<SwitchAccountError>());
    });
  });
}
