import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class BookWizardState extends Equatable {
  const BookWizardState({
    required this.title,
    this.coverImage,
    this.author,
    this.genre,
    this.availableGenres = const [],
  });

  final String title;
  final Uint8List? coverImage;
  final String? author;
  final String? genre;
  final List<String> availableGenres;

  BookWizardState copyWith({
    String? title,
    Uint8List? coverImage,
    String? author,
    String? genre,
    List<String>? availableGenres,
    bool clearCover = false,
  }) {
    return BookWizardState(
      title: title ?? this.title,
      coverImage: clearCover ? null : (coverImage ?? this.coverImage),
      author: author ?? this.author,
      genre: genre ?? this.genre,
      availableGenres: availableGenres ?? this.availableGenres,
    );
  }

  @override
  List<Object?> get props => [
    title,
    coverImage,
    author,
    genre,
    availableGenres,
  ];
}
