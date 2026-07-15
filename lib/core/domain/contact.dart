class Contact {
  const Contact({
    required this.npub,
    this.displayName,
    this.picture,
    this.lud16,
    this.isFollow = false,
  });

  final String npub;
  final String? displayName;
  final String? picture;
  final String? lud16;
  final bool isFollow;

  String get label => (displayName != null && displayName!.trim().isNotEmpty)
      ? displayName!.trim()
      : shortNpub;

  String get shortNpub => npub.length <= 16
      ? npub
      : '${npub.substring(0, 12)}…${npub.substring(npub.length - 4)}';
}

class ContactException implements Exception {
  final String message;
  const ContactException(this.message);
  @override
  String toString() => 'ContactException: $message';
}
