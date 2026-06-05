import 'dart:math';

class ProfileMetaGenerator {
  ProfileMetaGenerator._();

  static final _random = Random();

  static const _adjectives = [
    'Grounded',
    'Decentralized',
    'Encrypted',
    'Debloated',
    'Kryptonian',
    'Gotham',
    'Bibliophilic',
    'Asynchronous',
    'Mnemonic',
    'Ephemeral',
    'Pseudonymous',
    'Uncensorable',
    'Elusive',
    'Literary',
    'Zapped',
  ];
  static const _nouns = [
    'Gargoyle',
    'Daemon',
    'Isolate',
    'Bunker',
    'Hound',
    'Sloth',
    'Phantom',
    'Wizard',
    'Pirate',
    'Yeti',
    'Sherlock',
    'Gnome',
    'Bookworm',
    'Cat',
    'Schrödinger',
    'Bibliophile',
    'Quill',
    'Owl',
    'Gossip',
    'Sphinx',
    'Library',
  ];

  static ({String displayName, String avatar}) generate({String? seed}) {
    final rng = seed != null ? Random(seed.hashCode) : _random;
    final adj = _adjectives[rng.nextInt(_adjectives.length)];
    final noun = _nouns[rng.nextInt(_nouns.length)];
    final name = '$adj $noun';
    final avatar =
        'https://api.dicebear.com/10.x/glyphs/svg?seed=${Uri.encodeComponent(name)}';
    return (displayName: name, avatar: avatar);
  }
}
