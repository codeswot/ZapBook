import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/presentation/bloc/book_edit_state.dart';

@injectable
class BookEditCubit extends Cubit<BookEditState> {
  BookEditCubit(@factoryParam CircleBook book)
    : super(
        BookEditState(
          book: book,
          title: book.title,
          author: book.author,
          genre: book.genre,
          genres: [],
        ),
      );

  void setTitle(String title) {}
  void setAuthor(String author) {}
  void setGenre(String? genre) {}
  Future<void> pickCover() async {}
  Future<CircleBook?> save() async => null;
}
