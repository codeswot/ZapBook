import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/features/library/data/marmot/book_group_datasource.dart';
import 'package:zapbook/features/library/domain/usecases/backfill_library.dart';
import 'package:zapbook/features/library/domain/usecases/delete_library_book.dart';
import 'package:zapbook/features/library/domain/usecases/share_book.dart';
import 'package:zapbook/features/library/domain/usecases/sync_welcomes.dart';
import 'package:zapbook/features/library/domain/usecases/touch_book_opened.dart';
import 'package:zapbook/features/library/domain/usecases/watch_library_books.dart';
import 'package:zapbook/features/library/presentation/bloc/library_state.dart';

@injectable
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._watchLibraryBooks,
    this._backfillLibrary,
    this._touchBookOpened,
    this._shareBook,
    this._syncWelcomes,
    this._deleteLibraryBook,
    this._identity,
    this._datasource,
    this._libraryRepository,
    this._contacts,
  ) : super(const LibraryLoading()) {
    _init();
  }

  final WatchLibraryBooks _watchLibraryBooks;
  final BackfillLibrary _backfillLibrary;
  final TouchBookOpened _touchBookOpened;
  final ShareBook _shareBook;
  final SyncWelcomes _syncWelcomes;
  final DeleteLibraryBook _deleteLibraryBook;
  final IdentityLocalDataSource _identity;
  final BookGroupDatasource _datasource;
  final LibraryRepository _libraryRepository;
  final ContactService _contacts;
  StreamSubscription<List<LibraryBook>>? _subscription;

  void markOpened(String id) => _touchBookOpened(id);

  Future<void> deleteBook(String id) => _deleteLibraryBook(id);

  Future<bool> isAdminOf(String bookId) async {
    final myNpub = await _identity.readNpub();
    if (myNpub == null) return false;
    final admins = await _datasource.adminNpubs(bookId);
    return admins.contains(myNpub);
  }

  Future<String> ownerLabelFor(String bookId) async {
    final admins = await _datasource.adminNpubs(bookId);
    if (admins.isEmpty) return '';
    final contact = await _contacts.resolve(admins.first);
    return contact.label;
  }

  Future<void> shareBook(String bookId, String memberNpub) =>
      _shareBook(bookId, memberNpub.trim());

  Future<void> _init() async {
    _subscription = _watchLibraryBooks().listen(
      (books) =>
          emit(books.isEmpty ? const LibraryEmpty() : LibraryLoaded(books)),
      onError: (Object error) => emit(LibraryError('$error')),
    );
    unawaited(_backgroundSync());
  }

  Future<void> _backgroundSync() async {
    try {
      final joined = await _syncWelcomes();
      await _backfillLibrary();
      if (joined > 0) {
        await _libraryRepository.refresh();
      }
    } on Exception catch (error) {
      emit(LibraryError('$error'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
