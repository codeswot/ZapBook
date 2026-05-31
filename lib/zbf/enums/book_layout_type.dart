enum BookLayoutType {
  textHeavy('text-heavy'),
  mixed('mixed'),
  illustration('illustration'),
  chapterOpener('chapter-opener');

  const BookLayoutType(this.wireValue);

  final String wireValue;

  static BookLayoutType fromWire(String value) {
    return BookLayoutType.values.firstWhere(
      (type) => type.wireValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unknown BookLayoutType'),
    );
  }
}
