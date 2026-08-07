import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/features/profile/domain/usecases/switch_account_usecases.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/switch_account_state.dart';
import 'package:zapbook/core/identity/bunker_signer_source.dart';

class MockSwitchAccountUseCases extends Mock implements SwitchAccountUseCases {}

class MockBunkerConnectResult extends Mock implements BunkerConnectResult {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockBunkerConnectResult());
  });

  late MockSwitchAccountUseCases usecases;

  setUp(() {
    usecases = MockSwitchAccountUseCases();
  });

  SwitchAccountCubit createCubit() => SwitchAccountCubit(usecases);

  group('SwitchAccountCubit', () {
    test('initial state is SwitchAccountLoading', () {
      final cubit = createCubit();
      expect(cubit.state, isA<SwitchAccountLoading>());
    });

    test('load populates accounts', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1', 'npub2']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
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
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1', 'npub2']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));
      when(() => usecases.setActive(any())).thenAnswer((_) => Future.value());
      when(() => usecases.reloadSession()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      await cubit.switchAccount('npub2');

      verify(() => usecases.setActive('npub2')).called(1);
      verify(() => usecases.reloadSession()).called(1);
    });

    test('removeAccount removes and reloads accounts', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1', 'npub2']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => usecases.removeAccount(any()),
      ).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      await cubit.removeAccount('npub2');

      verify(() => usecases.removeAccount('npub2')).called(1);
      verify(() => usecases.listNpubs()).called(2);
    });

    test('importAccount validates, persists, and reloads session', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => usecases.validateNsec(any()),
      ).thenAnswer((_) => Future.value(true));
      when(
        () => usecases.importAndPersist(any()),
      ).thenAnswer((_) => Future.value('npub2'));
      when(() => usecases.setActive(any())).thenAnswer((_) => Future.value());
      when(() => usecases.reloadSession()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.importAccount('nsec2');

      expect(result, isTrue, reason: "connectNostrConnect returned false");
      verify(() => usecases.validateNsec('nsec2')).called(1);
      verify(() => usecases.importAndPersist('nsec2')).called(1);
      verify(() => usecases.reloadSession()).called(1);
    });

    test('importAccount returns false on invalid nsec', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => usecases.validateNsec(any()),
      ).thenAnswer((_) => Future.value(false));

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.importAccount('invalid');

      expect(result, isFalse);
      expect(cubit.state, isA<SwitchAccountError>());
    });

    test('importAccount handles exception gracefully', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));
      when(
        () => usecases.validateNsec(any()),
      ).thenThrow(Exception('Simulated error'));

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.importAccount('invalid');

      expect(result, isFalse);
      expect(cubit.state, isA<SwitchAccountError>());
    });

    test('connectExternalSigner connects and switches account', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));

      when(
        () => usecases.connectExternalSigner(),
      ).thenAnswer((_) => Future.value('npub2'));
      when(() => usecases.setActive(any())).thenAnswer((_) => Future.value());
      when(() => usecases.reloadSession()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.connectExternalSigner();

      expect(result, isTrue, reason: "connectNostrConnect returned false");
      verify(() => usecases.connectExternalSigner()).called(1);
      verify(() => usecases.setActive('npub2')).called(1);
      verify(() => usecases.reloadSession()).called(1);
    });

    test('connectBunker connects and switches account', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));

      when(
        () => usecases.connectBunker(any()),
      ).thenAnswer((_) => Future.value('npub2'));
      when(() => usecases.setActive(any())).thenAnswer((_) => Future.value());
      when(() => usecases.reloadSession()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.connectBunker('bunker://test');

      expect(result, isTrue, reason: "connectNostrConnect returned false");
      verify(() => usecases.connectBunker('bunker://test')).called(1);
      verify(() => usecases.setActive('npub2')).called(1);
      verify(() => usecases.reloadSession()).called(1);
    });

    test('connectNostrConnect connects and switches account', () async {
      when(
        () => usecases.listNpubs(),
      ).thenAnswer((_) => Future.value(['npub1']));
      when(() => usecases.readNpub()).thenAnswer((_) => Future.value('npub1'));
      when(
        () => usecases.fetchMetadata(any()),
      ).thenAnswer((_) => Future.value(null));

      final connection = BunkerConnectResult(
        npub: 'npub2',
        connectionJson: '{}',
      );
      final session = NostrConnectSession(
        uri: 'nostrconnect://bunker',
        awaitConnection: () => Future.value(connection),
      );

      when(
        () => usecases.saveBunkerConnection(connection),
      ).thenAnswer((_) => Future.value());
      when(() => usecases.setActive(any())).thenAnswer((_) => Future.value());
      when(() => usecases.reloadSession()).thenAnswer((_) => Future.value());

      final cubit = createCubit();
      await cubit.load();

      final result = await cubit.connectNostrConnect(session);

      expect(result, isTrue);
      verify(() => usecases.saveBunkerConnection(connection)).called(1);
      verify(() => usecases.setActive('npub2')).called(1);
      verify(() => usecases.reloadSession()).called(1);
    });
  });
}
