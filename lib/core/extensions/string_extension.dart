extension StringFormatting on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    if (isEmpty) return this;
    return split(
      ' ',
    ).map((word) => word.isEmpty ? word : word.capitalize).join(' ');
  }

  String get uncapitalize {
    if (isEmpty) return this;
    return '${this[0].toLowerCase()}${substring(1)}';
  }

  String toNpubShort({int prefixChars = 8, int suffixChars = 4}) {
    if (!startsWith('npub1') || length <= prefixChars + suffixChars + 3) {
      return this;
    }
    final prefix = substring(0, prefixChars);
    final suffix = substring(length - suffixChars);
    return '$prefix…$suffix';
  }

  String toNpubReadable({int groupSize = 4}) {
    if (!startsWith('npub1')) return this;
    final chars = substring(5);
    final groups = <String>[];
    for (var i = 0; i < chars.length; i += groupSize) {
      final end = (i + groupSize > chars.length) ? chars.length : i + groupSize;
      groups.add(chars.substring(i, end));
    }
    return 'npub1 ${groups.join(' ')}';
  }

  bool get isNpub => startsWith('npub1') && length >= 63;

  int get wordCount {
    var count = 0;
    var inWord = false;
    final len = length;
    for (var i = 0; i < len; i++) {
      final char = codeUnitAt(i);
      final isWhitespace =
          char == 32 ||
          char == 10 ||
          char == 13 ||
          char == 9 ||
          char == 11 ||
          char == 12;
      if (isWhitespace) {
        inWord = false;
      } else if (!inWord) {
        inWord = true;
        count++;
      }
    }
    return count;
  }
}
