import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/core/data/search/book_search_index.dart';

@injectable
class BookTextSearchCubit extends Cubit<List<BookSearchHit>> {
  BookTextSearchCubit() : super(const []);

  void query(String raw) {}
  void clear() {}
}
