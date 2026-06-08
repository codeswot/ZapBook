enum ZapGesture {
  thumbsUp(label: 'Nice progress', emoji: '👍', sats: 100),
  clap(label: 'Well done', emoji: '👏', sats: 500),
  fire(label: 'You\'re on fire', emoji: '🔥', sats: 1000),
  rocket(label: 'To the moon', emoji: '🚀', sats: 2100),
  trophy(label: 'Champion', emoji: '🏆', sats: 5000),
  gift(label: 'Gift wrap', emoji: '🎁', sats: null);

  const ZapGesture({
    required this.label,
    required this.emoji,
    required this.sats,
  });

  final String label;
  final String emoji;
  final int? sats;
}
