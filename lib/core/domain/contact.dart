class Contact {
  const Contact({
    required this.npub,
    this.displayName,
    this.picture,
    this.lud16,
  });

  final String npub;
  final String? displayName;
  final String? picture;
  final String? lud16;

  String get label =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!.trim()
          : shortNpub;

  String get shortNpub => npub.length <= 16
      ? npub
      : '${npub.substring(0, 12)}…${npub.substring(npub.length - 4)}';
}
