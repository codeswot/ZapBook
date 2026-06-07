enum ZapGesture {
  thumbsUp(label: 'Nice progress', emoji: '👍', sats: 1),
  clap(label: 'Well done', emoji: '👏', sats: 2),
  fire(label: 'You\'re on fire', emoji: '🔥', sats: 1),
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
