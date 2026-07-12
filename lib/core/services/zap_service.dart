import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/domain/zap_gesture.dart';
import 'package:zapbook/core/services/lnurl_service.dart';
import 'package:zapbook/core/services/nwc_service.dart';
import 'package:zapbook/core/services/zap_support_service.dart';

import 'package:logging/logging.dart' as logging;

@lazySingleton
class ZapService {
  ZapService(this._lnurl, this._ndk, this._nwc, this._support);

  final LnurlService _lnurl;
  final Ndk _ndk;
  final NwcService _nwc;
  final ZapSupportService _support;
  final _log = logging.Logger('ZapService');

  Future<ZapResult> donate({required int amountSats, String? comment}) => send(
    recipientLud16: ZapbookConfig.lnAddress,
    recipientPubkey: ZapbookConfig.npub,
    targetEventId: '',
    gesture: ZapGesture.gift,
    customSats: amountSats,
    comment: comment,
  );

  Future<ZapResult> send({
    required String recipientLud16,
    required String recipientPubkey,
    required String targetEventId,
    required ZapGesture gesture,
    int? customSats,
    String? comment,
    String? circleId,
  }) async {
    final amountSats = gesture.sats ?? customSats ?? 21;
    if (amountSats <= 0) throw ZapException('Amount must be positive');

    final amountMillisats = amountSats * 1000;
    final isDonation = recipientPubkey == ZapbookConfig.npub;

    final feePercent = (isDonation || !_nwc.isConnected) ? 0 : _support.percent;
    final supportAmount = feePercent > 0
        ? (amountSats * feePercent / 100).round().clamp(1, amountSats)
        : 0;

    final mainZapFuture = _prepareZap(
      lud16: recipientLud16,
      pubkey: recipientPubkey,
      targetEventId: targetEventId,
      amountMillisats: amountMillisats,
      content: comment ?? gesture.label,
      circleId: circleId,
    );

    Future<({String invoice, String zapRequestId})?>? supportZapFuture;
    if (supportAmount > 0) {
      supportZapFuture =
          _prepareZap(
                lud16: ZapbookConfig.lnAddress,
                pubkey: ZapbookConfig.npub,
                targetEventId: '',
                amountMillisats: supportAmount * 1000,
                content: 'ZapBook support ($feePercent%)',
              )
              .then<({String invoice, String zapRequestId})?>((res) => res)
              .catchError((error, stack) {
                _log.warning('Support fee invoice failed', error, stack);
                return null;
              });
    }

    final mainZap = await mainZapFuture;
    final supportZap = await supportZapFuture;

    return ZapResult(
      invoice: mainZap.invoice,
      zapRequestId: mainZap.zapRequestId,
      amountSats: amountSats,
      gesture: gesture,
      recipientPubkey: recipientPubkey,
      targetEventId: targetEventId,
      supportInvoice: supportZap?.invoice,
      supportAmount: supportZap != null ? supportAmount : 0,
    );
  }

  Future<({String invoice, String zapRequestId})> _prepareZap({
    required String lud16,
    required String pubkey,
    required String targetEventId,
    required int amountMillisats,
    required String content,
    String? circleId,
  }) async {
    final payResponse = await _lnurl.resolveLightningAddress(lud16);

    if (amountMillisats < payResponse.minSendable) {
      throw ZapException('Amount below minimum');
    }
    if (amountMillisats > payResponse.maxSendable) {
      throw ZapException('Amount above maximum');
    }

    final (:nostr, :zapRequestId) = await _buildZapRequest(
      recipientPubkey: pubkey,
      targetEventId: targetEventId,
      amountMillisats: amountMillisats,
      content: content,
      circleId: circleId,
    );

    final invoice = await _lnurl.fetchInvoice(
      payResponse: payResponse,
      amountMillisats: amountMillisats,
      comment: content,
      nostr: nostr,
    );

    return (invoice: invoice.pr, zapRequestId: zapRequestId ?? '');
  }

  Future<({String? nostr, String? zapRequestId})> _buildZapRequest({
    required String recipientPubkey,
    required String targetEventId,
    required int amountMillisats,
    required String content,
    String? circleId,
  }) async {
    final account = _ndk.accounts.getLoggedAccount();
    if (account == null ||
        !account.signer.canSign() ||
        recipientPubkey.isEmpty) {
      return (nostr: null, zapRequestId: null);
    }

    final recipientHex = recipientPubkey.startsWith('npub')
        ? Nip19.decode(recipientPubkey)
        : recipientPubkey;

    final tags = [
      ['relays', ...ZapbookConfig.broadcastRelays],
      ['amount', amountMillisats.toString()],
      ['p', recipientHex],
      ['client', 'zapbook'],
    ];
    if (targetEventId.isNotEmpty) {
      tags.add([targetEventId.contains(':') ? 'a' : 'e', targetEventId]);
    }
    if (circleId != null && circleId.isNotEmpty) {
      tags.add(['circle', circleId]);
    }

    final request = Nip01Event(
      pubKey: account.pubkey,
      kind: 9734,
      tags: tags,
      content: content,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final signed = await account.signer.sign(request);

    final nostr = jsonEncode({
      'id': signed.id,
      'pubkey': signed.pubKey,
      'created_at': signed.createdAt,
      'kind': signed.kind,
      'tags': signed.tags,
      'content': signed.content,
      'sig': signed.sig,
    });
    return (nostr: nostr, zapRequestId: signed.id);
  }

  Future<ZapStatus> payZap(ZapResult result) async {
    if (_nwc.isConnected) {
      try {
        final response = await _nwc.payInvoice(result.invoice);
        final preimage = response.preimage ?? '';
        if (preimage.isNotEmpty) {
          if (result.hasSupportZap) {
            final supportInvoice = result.supportInvoice ?? '';
            try {
              if (supportInvoice.isNotEmpty) {
                await _nwc.payInvoice(supportInvoice);
              } else {
                _log.warning('Support payment failed, no invoice');
              }
            } catch (error, stack) {
              _log.warning('Support payment failed', error, stack);
            }
          }
          return ZapStatus.paidNwc;
        }
      } catch (error, stack) {
        _log.warning('NWC zap failed', error, stack);
      }
    }

    final uri = Uri.tryParse('lightning:${result.invoice}');
    if (uri == null) return ZapStatus.failed;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return opened ? ZapStatus.pendingExternal : ZapStatus.failed;
  }

  Future<ZapStatus> payWithFallback(String invoice) async {
    if (_nwc.isConnected) {
      try {
        final response = await _nwc.payInvoice(invoice);
        final preimage = response.preimage ?? '';

        if (preimage.isNotEmpty) {
          return ZapStatus.paidNwc;
        }
      } catch (error, stack) {
        _log.warning(
          'NWC payment failed, falling back to external wallet',
          error,
          stack,
        );
      }
    }

    final uri = Uri.tryParse('lightning:$invoice');
    if (uri == null) return ZapStatus.failed;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return opened ? ZapStatus.pendingExternal : ZapStatus.failed;
  }

  Stream<bool> waitForReceipt(
    String zapRequestId, {
    Duration timeout = const Duration(minutes: 2),
  }) async* {
    final response = _ndk.requests.subscription(
      filter: Filter(
        kinds: const [9735],
        tags: {
          '#e': [zapRequestId],
        },
      ),
    );

    try {
      await for (final _ in response.stream.timeout(timeout)) {
        yield true;
        return;
      }
    } on TimeoutException {
      yield false;
    } finally {
      _ndk.requests.closeSubscription(response.requestId);
    }
  }
}

class ZapResult {
  final String invoice;
  final String zapRequestId;
  final int amountSats;
  final ZapGesture gesture;
  final String recipientPubkey;
  final String targetEventId;
  final String? supportInvoice;
  final int supportAmount;

  bool get hasSupportZap => supportInvoice != null && supportAmount > 0;

  const ZapResult({
    required this.invoice,
    required this.zapRequestId,
    required this.amountSats,
    required this.gesture,
    required this.recipientPubkey,
    required this.targetEventId,
    this.supportInvoice,
    this.supportAmount = 0,
  });
}

class ZapException implements Exception {
  final String message;
  const ZapException(this.message);
  @override
  String toString() => 'ZapException: $message';
}

enum ZapStatus { paidNwc, pendingExternal, failed }
