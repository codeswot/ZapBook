final class AssetNaming {
  const AssetNaming._();

  static const String coverAsset = 'cover.jpg';

  static const String sourceDocument = 'source.pdf';

  static String imageAsset(int index, String extension) {
    final padded = index.toString().padLeft(3, '0');
    return 'img_$padded.$extension';
  }

  static String chapterFile(int index) {
    final padded = (index + 1).toString().padLeft(3, '0');
    return 'ch_$padded.json';
  }

  static final RegExp _chapterFilePattern = RegExp(r'ch_(\d+)\.json$');
  static final RegExp _nonAlphanumeric = RegExp(r'[^a-z0-9]+');
  static final RegExp _edgeDashes = RegExp(r'^-+|-+$');

  static int chapterIndexFromFile(String fileName) {
    final match = _chapterFilePattern.firstMatch(fileName);
    final group = match?.group(1);
    if (group == null) {
      throw ArgumentError.value(fileName, 'fileName', 'Not a chapter file');
    }
    return int.parse(group) - 1;
  }

  static String slugify(String title) {
    final lower = title.toLowerCase().trim();
    final slug = lower
        .replaceAll(_nonAlphanumeric, '-')
        .replaceAll(_edgeDashes, '');
    return slug.isEmpty ? 'book' : slug;
  }
}
