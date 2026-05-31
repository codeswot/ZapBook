enum BookSourceFormat {
  pdf('pdf'),
  docx('docx'),
  epub('epub'),
  txt('txt');

  const BookSourceFormat(this.wireValue);

  final String wireValue;

  static BookSourceFormat fromWire(String value) {
    return BookSourceFormat.values.firstWhere(
      (format) => format.wireValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unknown BookSourceFormat'),
    );
  }

  static BookSourceFormat? fromExtension(String extension) {
    final normalised = extension.toLowerCase().replaceFirst('.', '');
    for (final format in BookSourceFormat.values) {
      if (format.wireValue == normalised) {
        return format;
      }
    }
    return null;
  }
}
