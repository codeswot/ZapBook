final class AssetNaming {
  const AssetNaming._();

  static const String coverAsset = 'cover.png';

  /// Original source document, stashed only when a book needs AI processing so
  /// flagged pages can be re-rendered for Zb later. Lives in the ZBF root.
  static const String sourceDocument = 'source.pdf';

  static String imageAsset(int index, String extension) {
    final padded = index.toString().padLeft(3, '0');
    return 'img_$padded.$extension';
  }

  static String chapterFile(int index) {
    final padded = (index + 1).toString().padLeft(3, '0');
    return 'ch_$padded.json';
  }

  static int chapterIndexFromFile(String fileName) {
    final match = RegExp(r'ch_(\d+)\.json$').firstMatch(fileName);
    final group = match?.group(1);
    if (group == null) {
      throw ArgumentError.value(fileName, 'fileName', 'Not a chapter file');
    }
    return int.parse(group) - 1;
  }

  static String slugify(String title) {
    final lower = title.toLowerCase().trim();
    final slug = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'book' : slug;
  }
}
