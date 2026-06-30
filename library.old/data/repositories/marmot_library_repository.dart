import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/dao/page_dao.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/data/search/book_search_index.dart';
import 'package:zapbook/core/data/search/book_vector_index.dart';
import 'package:zapbook/core/services/circle_store_service.dart';
import 'package:zapbook/core/services/density_service.dart';
import 'package:zapbook/core/services/group_store_service.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/features/library/data/marmot/book_circle_datasource.dart';
import 'package:zapbook/features/library/domain/entities/share_skip.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/zbf/zbf.dart';

@LazySingleton(as: LibraryRepository)
class MarmotLibraryRepository implements LibraryRepository {
  MarmotLibraryRepository(
    this._datasource,
    this._fileStore,
    this._reader,
    this._density,
    this._searchIndex,
    this._vectorIndex,
    this._pageCache,
    this._groupStore,
    this._circleStore,
  );

  final BookCircleDatasource _datasource;
  final LibraryFileStore _fileStore;
  final ZbfReader _reader;
  final DensityService _density;
  final BookSearchIndex _searchIndex;
  final BookVectorIndex _vectorIndex;
  final PageDao _pageCache;
  final GroupStoreService _groupStore;
  final CircleStoreService _circleStore;

  final _log = logging.Logger('MarmotLibraryRepository');

  @override
  Stream<List<CircleBook>> watchBooks() => _circleStore.watchCircleBooks;

  @override
  Future<CircleBook?> getBook(String id) async {
    final circles = _circleStore.currentCircles;
    for (final circle in circles) {
      if (circle.id == id) return circle;
    }
    // If not found instantly, we can just return null or wait for the stream.
    return null;
  }

  @override
  Future<CircleBook?> findByContentHash(String contentHash) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<CircleBook> addBookFromIngestion(
    ZbfBook book,
    String zbfPath, {
    String? contentHash,
  }) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<CircleBook> indexExisting(String zbfPath) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<CircleBook> updateBookMetadata(
    String id, {
    required String title,
    String? author,
    String? genre,
    Uint8List? coverImage,
  }) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<void> deleteBook(String id) async {
    await _datasource.deleteCircle(id);
    await _groupStore.deleteGroup(id);
    await _fileStore.deleteBook(id);
  }

  @override
  Future<void> touchOpened(String id) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<List<ShareSkip>> shareBook(String id, String memberNpub) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<List<ShareSkip>> shareBookWith(
    String id,
    List<String> memberNpubs,
  ) async {
    throw UnimplementedError('To be implemented');
  }

  @override
  Future<List<String>> bookMembers(String id) async {
    return _datasource.members(id).then((m) => m.map((x) => x.npub).toList());
  }

  @override
  Future<List<String>> bookAdmins(String id) async {
    return _datasource.adminNpubs(id);
  }

  @override
  Future<void> removeBookMember(String id, String memberNpub) async {
    await _datasource.removeMember(id, memberNpub);
  }

  @override
  Future<void> leaveCircle(String id) async {
    await _datasource.leaveCircle(id);
    await _groupStore.deleteGroup(id);
    await _fileStore.deleteBook(id);
  }

  @override
  Future<void> dissolveCircle(String id) async {
    await _datasource.dissolveCircle(id);
    await _groupStore.deleteGroup(id);
    await _fileStore.deleteBook(id);
  }

  @override
  Future<void> refresh() async {
    // No-op, managed by watchGroups/watchCircles
  }

  @override
  Future<void> backfill() async {
    throw UnimplementedError('To be implemented');
  }
}
