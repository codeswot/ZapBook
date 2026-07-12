import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:zapbook/core/services/lnurl_service.dart';
import 'package:zapbook/core/models/lnurl_models.dart';
import 'package:zapbook/core/utils/bolt11_utils.dart';

class MockClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockClient mockClient;
  late LnurlService service;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockClient = MockClient();
    service = LnurlService(client: mockClient);
  });

  group('LnurlService', () {
    test(
      'resolveLightningAddress throws LnurlException on invalid format',
      () async {
        expect(
          () => service.resolveLightningAddress('invalid'),
          throwsA(isA<LnurlException>()),
        );
      },
    );

    test(
      'resolveLightningAddress throws LnurlException on forbidden host',
      () async {
        expect(
          () => service.resolveLightningAddress('user@localhost'),
          throwsA(isA<LnurlException>()),
        );
      },
    );

    test('resolveLightningAddress successful resolution', () async {
      final url = Uri.https('example.com', '/.well-known/lnurlp/user');
      when(() => mockClient.get(url)).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'tag': 'payRequest',
            'callback': 'https://example.com/callback',
            'minSendable': 1000,
            'maxSendable': 100000000,
          }),
          200,
        ),
      );

      final response = await service.resolveLightningAddress(
        'user@example.com',
      );

      expect(response.callback.toString(), 'https://example.com/callback');
      expect(response.minSendable, 1000);
      expect(response.maxSendable, 100000000);

      // Cached value
      final cached = await service.resolveLightningAddress('user@example.com');
      expect(cached, response);
      verify(() => mockClient.get(url)).called(1);
    });

    test('resolveLightningAddress handles 404', () async {
      final url = Uri.https('example.com', '/.well-known/lnurlp/user');
      when(
        () => mockClient.get(url),
      ).thenAnswer((_) async => http.Response('', 404));

      expect(
        () => service.resolveLightningAddress('user@example.com'),
        throwsA(isA<LnurlException>()),
      );
    });

    test('bolt11AmountMillisats extracts amount', () {
      final msats = Bolt11Utils.amountMillisats('lnbc100n1...');
      expect(msats, 10000);
    });

    test('bolt11AmountMillisats throws on invalid prefix', () {
      expect(
        () => Bolt11Utils.amountMillisats('invalid'),
        throwsA(isA<LnurlException>()),
      );
    });

    test('fetchInvoice success', () async {
      final payResponse = LnurlPayResponse(
        callback: Uri.parse('https://example.com/callback'),
        minSendable: 1000,
        maxSendable: 100000000,
      );

      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode({'pr': 'lnbc10n1...'}), 200),
      );

      final invoice = await service.fetchInvoice(
        payResponse: payResponse,
        amountMillisats: 1000,
      );

      expect(invoice.pr, 'lnbc10n1...');
    });
  });
}
