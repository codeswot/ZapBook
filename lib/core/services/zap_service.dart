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

    final payResponse = await _lnurl.resolveLightningAddress(recipientLud16);

    if (amountMillisats < payResponse.minSendable) {
      throw ZapException('Amount below minimum');
    }
    if (amountMillisats > payResponse.maxSendable) {
      throw ZapException('Amount above maximum');
    }

    final nostr = await _buildZapRequest(
      recipientPubkey: recipientPubkey,
      targetEventId: targetEventId,
      amountMillisats: amountMillisats,
      content: comment ?? gesture.label,
      circleId: circleId,
    );

    final invoice = await _lnurl.fetchInvoice(
      payResponse: payResponse,
      amountMillisats: amountMillisats,
      comment: comment ?? gesture.label,
      nostr: nostr,
    );

    String? supportInvoice;
    int supportAmount = 0;
    final isDonation = recipientPubkey == ZapbookConfig.npub;
    final feePercent = (isDonation || !_nwc.isConnected) ? 0 : _support.percent;
    if (feePercent > 0) {
      supportAmount = (amountSats * feePercent / 100).round().clamp(
        1,
        amountSats,
      );
      if (supportAmount > 0) {
        try {
          final supportNostr = await _buildZapRequest(
            recipientPubkey: ZapbookConfig.npub,
            targetEventId: '',
            amountMillisats: supportAmount * 1000,
            content: 'ZapBook support ($feePercent%)',
          );
          final supportPayResponse = await _lnurl.resolveLightningAddress(
            ZapbookConfig.lnAddress,
          );
          final supportInv = await _lnurl.fetchInvoice(
            payResponse: supportPayResponse,
            amountMillisats: supportAmount * 1000,
            comment: 'ZapBook support ($feePercent%)',
            nostr: supportNostr,
          );
          supportInvoice = supportInv.pr;
        } catch (error, stack) {
          _log.warning('Support fee invoice failed', error, stack);
        }
      }
    }

    return ZapResult(
      invoice: invoice.pr,
      amountSats: amountSats,
      gesture: gesture,
      recipientPubkey: recipientPubkey,
      targetEventId: targetEventId,
      supportInvoice: supportInvoice,
      supportAmount: supportAmount,
    );
  }

  Future<String?> _buildZapRequest({
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
      return null;
    }

    final recipientHex = recipientPubkey.startsWith('npub')
        ? Nip19.decode(recipientPubkey)
        : recipientPubkey;

    final tags = [
      ['relays', ..._zapReceiptRelays],
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

    return jsonEncode({
      'id': signed.id,
      'pubkey': signed.pubKey,
      'created_at': signed.createdAt,
      'kind': signed.kind,
      'tags': signed.tags,
      'content': signed.content,
      'sig': signed.sig,
    });
  }

  static const _zapReceiptRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
  ];

  Future<bool> payZap(ZapResult result) async {
    if (_nwc.isConnected) {
      try {
        final response = await _nwc.payInvoice(result.invoice);
        if (response.preimage != null && response.preimage!.isNotEmpty) {
          if (result.hasSupportZap) {
            try {
              await _nwc.payInvoice(result.supportInvoice!);
            } catch (error, stack) {
              _log.warning('Support payment failed', error, stack);
            }
          }
          return true;
        }
      } catch (error, stack) {
        _log.warning('NWC zap failed', error, stack);
      }
    }

    final uri = Uri.tryParse('lightning:${result.invoice}');
    if (uri == null) return false;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened && result.hasSupportZap) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final supportUri = Uri.tryParse('lightning:${result.supportInvoice}');
      if (supportUri != null) {
        unawaited(launchUrl(supportUri, mode: LaunchMode.externalApplication));
      }
    }
    return opened;
  }

  Future<bool> payWithFallback(String invoice) async {
    if (_nwc.isConnected) {
      try {
        final response = await _nwc.payInvoice(invoice);
        if (response.preimage != null && response.preimage!.isNotEmpty) {
          return true;
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
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  NdkResponse subscribeToReceipts({required String targetEventId}) {
    return _ndk.requests.subscription(
      filter: Filter(
        kinds: const [9735],
        tags: {
          '#e': [targetEventId],
        },
      ),
    );
  }
}

class ZapResult {
  final String invoice;
  final int amountSats;
  final ZapGesture gesture;
  final String recipientPubkey;
  final String targetEventId;
  final String? supportInvoice;
  final int supportAmount;

  bool get hasSupportZap => supportInvoice != null && supportAmount > 0;

  const ZapResult({
    required this.invoice,
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
