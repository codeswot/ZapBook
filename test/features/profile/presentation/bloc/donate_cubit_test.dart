import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/lnurl_service.dart';
import 'package:zapbook/core/services/zap_service.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_cubit.dart';
import 'package:zapbook/features/profile/presentation/bloc/donate_state.dart';

class MockZapService extends Mock implements ZapService {}

void main() {
  late MockZapService zapService;

  const tZapResult = ZapResult(
    invoice: 'lnbc1...',
    zapRequestId: 'id',
    amountSats: 2100,
    gesture: ZapGesture.rocket,
    recipientPubkey: 'pubkey',
    targetEventId: 'event',
  );

  setUp(() {
    zapService = MockZapService();
  });

  DonateCubit buildCubit() => DonateCubit(zapService);

  group('DonateCubit', () {
    test('initial state is DonateReady', () {
      final cubit = buildCubit();
      expect(cubit.state, const DonateReady());
      expect(cubit.recipient, 'zapbook@blink.sv');
    });

    blocTest<DonateCubit, DonateState>(
      'toggleGift toggles showGift from Ready',
      build: buildCubit,
      act: (cubit) => cubit.toggleGift(),
      expect: () => [const DonateReady(showGift: true)],
    );

    blocTest<DonateCubit, DonateState>(
      'toggleGift toggles showGift from Failure',
      build: buildCubit,
      seed: () => const DonateFailure(showGift: false, userMessage: 'Error'),
      act: (cubit) => cubit.toggleGift(),
      expect: () => [const DonateFailure(showGift: true, userMessage: 'Error')],
    );

    blocTest<DonateCubit, DonateState>(
      'toggleGift does nothing from Loading or Success',
      build: buildCubit,
      seed: () => const DonateLoading(showGift: false),
      act: (cubit) => cubit.toggleGift(),
      expect: () => [],
    );

    blocTest<DonateCubit, DonateState>(
      'sendPreset success',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => zapService.donate(
            amountSats: 2100,
            comment: 'ZapBook To the moon!',
          ),
        ).thenAnswer((_) async => tZapResult);
        await cubit.sendPreset(ZapGesture.rocket);
      },
      expect: () => [
        const DonateLoading(showGift: false, presetChip: ZapGesture.rocket),
        const DonateSuccess('lnbc1...'),
      ],
      verify: (_) {
        verify(
          () => zapService.donate(
            amountSats: 2100,
            comment: 'ZapBook To the moon!',
          ),
        ).called(1);
      },
    );

    blocTest<DonateCubit, DonateState>(
      'sendPreset failure mapped from SocketException',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => zapService.donate(
            amountSats: 2100,
            comment: 'ZapBook To the moon!',
          ),
        ).thenThrow(const SocketException('failed'));
        await cubit.sendPreset(ZapGesture.rocket);
      },
      expect: () => [
        const DonateLoading(showGift: false, presetChip: ZapGesture.rocket),
        const DonateFailure(
          showGift: false,
          userMessage: 'No internet connection',
        ),
      ],
    );

    blocTest<DonateCubit, DonateState>(
      'sendGift success',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => zapService.donate(amountSats: 100, comment: 'gift'),
        ).thenAnswer((_) async => tZapResult);
        await cubit.sendGift(100, 'gift');
      },
      expect: () => [
        const DonateLoading(showGift: false),
        const DonateSuccess('lnbc1...'),
      ],
      verify: (_) {
        verify(
          () => zapService.donate(amountSats: 100, comment: 'gift'),
        ).called(1);
      },
    );

    blocTest<DonateCubit, DonateState>(
      'sendGift failure mapped from ZapException',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => zapService.donate(amountSats: 100, comment: null),
        ).thenThrow(const ZapException('Zap error'));
        await cubit.sendGift(100, null);
      },
      expect: () => [
        const DonateLoading(showGift: false),
        const DonateFailure(showGift: false, userMessage: 'Zap error'),
      ],
    );

    blocTest<DonateCubit, DonateState>(
      'sendGift failure mapped from LnurlException',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => zapService.donate(amountSats: 100, comment: null),
        ).thenThrow(const LnurlException('Lnurl error'));
        await cubit.sendGift(100, '');
      },
      expect: () => [
        const DonateLoading(showGift: false),
        const DonateFailure(showGift: false, userMessage: 'Lnurl error'),
      ],
    );

    blocTest<DonateCubit, DonateState>(
      'sendGift failure mapped from general Exception',
      build: buildCubit,
      act: (cubit) async {
        when(
          () => zapService.donate(amountSats: 100, comment: null),
        ).thenThrow(Exception('Fail'));
        await cubit.sendGift(100, '');
      },
      expect: () => [
        const DonateLoading(showGift: false),
        const DonateFailure(
          showGift: false,
          userMessage: 'Something went wrong, try again',
        ),
      ],
    );
  });
}
