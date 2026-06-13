import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/core/data/datasources/onboarding_local_datasource.dart';
import 'package:zapbook/core/identity/identity_local_data_source.dart';
import 'package:zapbook/core/services/contact_service.dart';
import 'package:zapbook/core/services/welcome_inbox_service.dart';
import 'package:zapbook/features/library/data/marmot/book_group_datasource.dart';
import 'package:zapbook/features/library/domain/usecases/backfill_library.dart';
import 'package:zapbook/features/library/domain/usecases/delete_library_book.dart';
import 'package:zapbook/features/library/domain/usecases/share_book.dart';
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
    this._deleteLibraryBook,
    this._identity,
    this._datasource,
    this._libraryRepository,
    this._contacts,
    this._welcomeInbox,
    this._onboarding,
  ) : super(const LibraryLoading()) {
    _init();
    _circlePromptShown = _onboarding.circlePromptShown();
  }

  final WatchLibraryBooks _watchLibraryBooks;
  final BackfillLibrary _backfillLibrary;
  final TouchBookOpened _touchBookOpened;
  final ShareBook _shareBook;
  final DeleteLibraryBook _deleteLibraryBook;
  final IdentityLocalDataSource _identity;
  final BookGroupDatasource _datasource;
  final LibraryRepository _libraryRepository;
  final ContactService _contacts;
  final WelcomeInboxService _welcomeInbox;
  final OnboardingLocalDataSource _onboarding;
  StreamSubscription<List<LibraryBook>>? _booksSubscription;
  StreamSubscription<int>? _welcomeSubscription;
  bool _circlePromptShown = false;

  void markOpened(String id) => _touchBookOpened(id);

  void dismissCirclePrompt() {
    final s = state;
    if (s is LibraryLoaded) {
      emit(LibraryLoaded(s.books, showCirclePrompt: false));
    }
  }

  Future<void> deleteBook(String id) => _deleteLibraryBook(id);

  Future<void> leaveCircle(String id) => _libraryRepository.leaveCircle(id);

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
    _booksSubscription = _watchLibraryBooks().listen((books) {
      if (books.isEmpty) {
        emit(const LibraryEmpty());
      } else {
        final show = !_circlePromptShown && books.length == 1;
        if (show) {
          _circlePromptShown = true;
          _onboarding.setCirclePromptShown();
        }
        emit(LibraryLoaded(books, showCirclePrompt: show));
      }
    }, onError: (Object error) => emit(LibraryError('$error')));
    _welcomeSubscription = _welcomeInbox.onJoined.listen((_) {
      _libraryRepository.refresh();
    });
    unawaited(_backgroundSync());
  }

  Future<void> _backgroundSync() async {
    try {
      await _backfillLibrary();
      await _libraryRepository.refresh();
    } on Exception catch (error) {
      emit(LibraryError('$error'));
    }
  }

  @override
  Future<void> close() async {
    await _booksSubscription?.cancel();
    await _welcomeSubscription?.cancel();
    return super.close();
  }
}
