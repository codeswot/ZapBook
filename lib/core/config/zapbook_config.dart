class ZapbookConfig {
  const ZapbookConfig._();

  static const lnAddress = 'zapbook@cake.cash';
  static const npub =
      'npub1h50eaqvqlslw9y9qwh5ktagxu3a63fvg3e9ck4hvw47fkctgmvgqrc7qqe';

  static const List<String> broadcastRelays = [
    'wss://relay.primal.net',
    'wss://nos.lol',
    'wss://relay.snort.social',
  ];
}
