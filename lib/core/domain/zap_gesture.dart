enum ZapGesture {
  thumbsUp(id: 'like', label: 'Nice progress', emoji: '👍', sats: 100),
  clap(id: 'clap', label: 'Well done', emoji: '👏', sats: 500),
  fire(id: 'fire', label: 'You\'re on fire', emoji: '🔥', sats: 1000),
  rocket(id: 'rocket', label: 'To the moon', emoji: '🚀', sats: 2100),
  trophy(id: 'trophy', label: 'Champion', emoji: '🏆', sats: 5000),
  gift(id: 'gift', label: 'Gift wrap', emoji: '🎁', sats: null);

  const ZapGesture({
    required this.id,
    required this.label,
    required this.emoji,
    required this.sats,
  });

  final String id;
  final String label;
  final String emoji;
  final int? sats;

  static ZapGesture fromId(String id) {
    return ZapGesture.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ZapGesture.thumbsUp,
    );
  }
}
