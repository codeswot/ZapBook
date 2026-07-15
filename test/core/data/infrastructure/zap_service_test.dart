import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ndk/ndk.dart';
import 'package:zapbook/core/models/lnurl_models.dart';
import 'package:zapbook/core/data/database/dao/zap_sats_earnings_dao.dart';
import 'package:zapbook/core/data/infrastructure/lnurl_service.dart';
import 'package:zapbook/core/data/infrastructure/nwc_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_service.dart';
import 'package:zapbook/core/data/infrastructure/zap_support_service.dart';
import 'package:zapbook/core/domain/entities/zap_status.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';

class MockLnurlService extends Mock implements LnurlService {}

class MockNdk extends Mock implements Ndk {}

class MockNwcService extends Mock implements NwcService {}

class MockZapSupportService extends Mock implements ZapSupportService {}

class MockAccounts extends Mock implements Accounts {}

class MockRequests extends Mock implements Requests {}

class MockAccount extends Mock implements Account {}

class MockEventSigner extends Mock implements EventSigner {}

void main() {
  late MockLnurlService lnurl;
  late MockNdk ndk;
  late MockNwcService nwc;
  late MockZapSupportService support;
  late ZapService service;
  late MockAccounts accountManager;
  late MockRequests requestManager;
  late MockAccount account;
  late MockEventSigner signer;

  setUpAll(() {
    registerFallbackValue(ZapType.profile);
    registerFallbackValue(
      Nip01Event(pubKey: 'a', kind: 1, tags: [], content: '', createdAt: 0),
    );
  });

  setUp(() {
    lnurl = MockLnurlService();
    ndk = MockNdk();
    nwc = MockNwcService();
    support = MockZapSupportService();
    accountManager = MockAccounts();
    requestManager = MockRequests();
    account = MockAccount();
    signer = MockEventSigner();

    when(() => ndk.accounts).thenReturn(accountManager);
    when(() => ndk.requests).thenReturn(requestManager);
    when(() => accountManager.getLoggedAccount()).thenReturn(account);
    when(() => account.signer).thenReturn(signer);
    when(() => account.pubkey).thenReturn('my_pubkey');
    when(() => signer.canSign()).thenReturn(true);
    when(() => signer.getPublicKey()).thenReturn('my_pubkey');

    when(() => signer.sign(any())).thenAnswer((inv) async {
      final event = inv.positionalArguments[0] as Nip01Event;
      return Nip01Event(
        id: 'dummy_id',
        pubKey: event.pubKey,
        createdAt: event.createdAt,
        kind: event.kind,
        tags: event.tags,
        content: event.content,
        sig: 'dummy_sig',
      );
    });

    when(() => support.percent).thenReturn(0);
    when(() => nwc.isConnected).thenReturn(false);

    service = ZapService(lnurl, ndk, nwc, support);
  });

  group('ZapService', () {
    test('send throws exception if amount is <= 0', () async {
      expect(
        () => service.send(
          recipientLud16: 'test@lud16',
          recipientPubkey: 'target_pubkey',
          targetActivitytId: 'target',
          gesture: ZapGesture.gift,
          customSats: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('send returns ZapResult on success', () async {
      final payResponse = LnurlPayResponse(
        callback: Uri.parse('https://example.com/cb'),
        maxSendable: 1000000,
        minSendable: 1000,
        metadata: 'metadata',
        commentAllowed: 255,
      );

      when(
        () => lnurl.resolveLightningAddress('test@alby.com'),
      ).thenAnswer((_) async => payResponse);
      when(
        () => lnurl.fetchInvoice(
          payResponse: payResponse,
          amountMillisats: 21000,
          comment: 'comment',
          nostr: any(named: 'nostr'),
        ),
      ).thenAnswer((_) async => LnurlInvoice(pr: 'lnbc1_invoice', routes: []));

      final result = await service.send(
        recipientLud16: 'test@alby.com',
        recipientPubkey: 'npub1target',
        targetActivitytId: 'target',
        gesture: ZapGesture.gift,
        customSats: 21,
        comment: 'comment',
      );

      expect(result.invoice, 'lnbc1_invoice');
      expect(result.amountSats, 21);
      expect(result.zapRequestId, 'dummy_id');
      expect(result.supportAmount, 0);
    });

    test('payZap returns paidNwc if NWC connected and successful', () async {
      final result = ZapResult(
        invoice: 'lnbc1_invoice',
        zapRequestId: 'req1',
        amountSats: 21,
        gesture: ZapGesture.gift,
        recipientPubkey: 'pubkey',
        targetActivitytId: 'target',
        supportAmount: 0,
      );

      when(() => nwc.isConnected).thenReturn(true);
      when(() => nwc.payInvoice('lnbc1_invoice')).thenAnswer(
        (_) async => PayInvoiceResponse(
          preimage: 'preimage',
          resultType: 'pay_invoice',
          feesPaid: 0,
        ),
      );

      final status = await service.payZap(result);
      expect(status, ZapStatus.paidNwc);
    });
  });
}
