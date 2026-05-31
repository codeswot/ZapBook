import 'package:injectable/injectable.dart';

@lazySingleton
class GenreDataSource {
  List<String> getGenres() {
    return [
      'Fiction',
      'Non-Fiction',
      'Sci-Fi',
      'Fantasy',
      'Mystery',
      'Biography',
      'History',
      'Romance',
      'Poetry',
    ];
  }
}
