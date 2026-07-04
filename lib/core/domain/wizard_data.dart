import 'dart:typed_data';

final class WizardData {
  const WizardData({this.title, this.coverImage, this.author, this.genre});

  final String? title;
  final Uint8List? coverImage;
  final String? author;
  final String? genre;
}

final class WizardInitialData {
  const WizardInitialData({this.title, this.author});

  final String? title;
  final String? author;
}
