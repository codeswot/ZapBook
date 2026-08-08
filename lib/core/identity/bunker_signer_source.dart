import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zapbook/core/config/zapbook_config.dart';
import 'package:zapbook/core/identity/signer_meta.dart';

class BunkerConnectResult {
  const BunkerConnectResult({required this.npub, required this.connectionJson});

  final String npub;
  final String connectionJson;
}

class NostrConnectSession {
  const NostrConnectSession({required this.uri, required this.awaitConnection});

  final String uri;
  final Future<BunkerConnectResult> Function({void Function()? onContact}) awaitConnection;
}

@lazySingleton
class BunkerSignerSource {
  BunkerSignerSource(this._ndk);

  final Ndk _ndk;
  final _log = logging.Logger('BunkerSignerSource');
  Future<EventSigner?> resolve(String connectionJson) async {
    final connection = _decode(connectionJson);
    if (connection == null) return null;
    final signer = _ndk.bunkers.createSigner(
      connection,
      authCallback: _openAuthUrl,
    );
    await signer.getPublicKeyAsync();
    return signer;
  }

  NostrConnectSession initiateNostrConnect({required String appName}) {
    final req = NostrConnect(
      relays: [...ZapbookConfig.broadcastRelays, 'wss://relay.nsecbunker.com'],
      appName: appName,
    );
    return NostrConnectSession(
      uri: req.nostrConnectURL,
      awaitConnection: ({void Function()? onContact}) async {
        BunkerConnection? connection;
        final localEventSigner = Bip340EventSigner(
          privateKey: req.keyPair.privateKey!,
          publicKey: req.keyPair.publicKey,
        );

        final subscription = _ndk.requests.subscription(
          explicitRelays: req.relays,
          filter: Filter(
            kinds: [24133, 4],
            pTags: [localEventSigner.getPublicKey()],
            since: (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 300,
          ),
        );

        await for (final event in subscription.stream.timeout(
          const Duration(minutes: 5),
        )) {
          try {
            String? decryptedContent;
            bool isNip44 = false;

            try {
              decryptedContent = await localEventSigner.decryptNip44(
                ciphertext: event.content,
                senderPubKey: event.pubKey,
              );
              isNip44 = decryptedContent != null;
            } catch (_) {}

            if (decryptedContent == null) {
              try {
                decryptedContent = await localEventSigner.decrypt(
                  event.content,
                  event.pubKey,
                );
              } catch (_) {}
            }

            if (decryptedContent == null) continue;

            final response =
                jsonDecode(decryptedContent) as Map<String, dynamic>;

            if (response['result'] != null && response['error'] == null) {
              final receivedSecret = response['result'].toString().replaceAll(
                '=',
                '',
              );
              final expectedSecret = req.secret.replaceAll('=', '');
              if (receivedSecret.startsWith(expectedSecret) ||
                  expectedSecret.startsWith(receivedSecret)) {
                connection = BunkerConnection(
                  privateKey: req.keyPair.privateKey!,
                  remotePubkey: event.pubKey,
                  relays: req.relays,
                );
                break;
              }
            } else if (response['method'] == 'connect' &&
                response['params'] is List &&
                (response['params'] as List).isNotEmpty) {
              final paramsList = response['params'] as List;
              final rcvSecret = paramsList.length > 1 ? paramsList[1] : null;

              final receivedSecret = rcvSecret?.toString().replaceAll('=', '');
              final expectedSecret = req.secret.replaceAll('=', '');

              if (req.secret.isEmpty ||
                  (receivedSecret != null &&
                      (receivedSecret.startsWith(expectedSecret) ||
                          expectedSecret.startsWith(receivedSecret))) ||
                  receivedSecret == null) {
                final ack = {
                  'id': response['id'],
                  'result': 'ack',
                  'error': null,
                };

                final encryptedAck = isNip44
                    ? await localEventSigner.encryptNip44(
                        plaintext: jsonEncode(ack),
                        recipientPubKey: event.pubKey,
                      )
                    : await localEventSigner.encrypt(
                        jsonEncode(ack),
                        event.pubKey,
                      );

                final ackEvent = Nip01Event(
                  pubKey: localEventSigner.getPublicKey(),
                  kind: event.kind,
                  tags: [
                    ['p', event.pubKey],
                  ],
                  content: encryptedAck!,
                );
                final signedAckEvent = await localEventSigner.sign(ackEvent);

                final broadcastRes = _ndk.broadcast.broadcast(
                  nostrEvent: signedAckEvent,
                  specificRelays: req.relays,
                );
                try {
                  await broadcastRes.broadcastDoneFuture.timeout(
                    const Duration(seconds: 3),
                  );
                } catch (e) {
                  _log.warning('Error broadcasting ack event: $e');
                }

                connection = BunkerConnection(
                  privateKey: req.keyPair.privateKey!,
                  remotePubkey: event.pubKey,
                  relays: req.relays,
                );
                break;
              }
            }
          } catch (e) {
            _log.warning('Error processing event: $e');
          }
        }
        await _ndk.requests.closeSubscription(subscription.requestId);

        if (connection == null) {
          throw const SignerUnavailable(
            'Signer did not confirm the connection',
          );
        }
        
        onContact?.call();

        final signer = _ndk.bunkers.createSigner(
          connection,
          authCallback: _openAuthUrl,
        );
        try {
          final raw = await signer.getPublicKeyAsync().timeout(
            const Duration(seconds: 15),
          );
          final npub = raw.startsWith('npub') ? raw : Nip19.encodePubKey(raw);
          return BunkerConnectResult(
            npub: npub,
            connectionJson: jsonEncode(connection.toJson()),
          );
        } catch (e) {
          throw SignerUnavailable('Failed to get public key: $e');
        }
      },
    );
  }

  Future<BunkerConnectResult> connect(String bunkerUrl) async {
    final trimmed = bunkerUrl.trim();
    if (!trimmed.startsWith('bunker://')) {
      throw const SignerMalformed('Enter a valid bunker:// connection link');
    }

    final BunkerConnection? connection;
    try {
      connection = await _ndk.bunkers.connectWithBunkerUrl(
        trimmed,
        authCallback: _openAuthUrl,
      );
    } on Object catch (error) {
      throw SignerUnavailable(error.toString());
    }
    if (connection == null) {
      throw const SignerUnavailable('Bunker did not confirm the connection');
    }

    final signer = _ndk.bunkers.createSigner(
      connection,
      authCallback: _openAuthUrl,
    );
    final raw = await signer.getPublicKeyAsync();
    final npub = raw.startsWith('npub') ? raw : Nip19.encodePubKey(raw);
    return BunkerConnectResult(
      npub: npub,
      connectionJson: jsonEncode(connection.toJson()),
    );
  }

  BunkerConnection? _decode(String connectionJson) {
    try {
      final map = jsonDecode(connectionJson) as Map<String, dynamic>;
      return BunkerConnection.fromJson(map);
    } on Object {
      return null;
    }
  }

  void _openAuthUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }
}
