import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;

import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/services/density_service.dart';
import 'package:zapbook/features/library/data/marmot/book_group_datasource.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
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
  );

  final BookGroupDatasource _datasource;
  final LibraryFileStore _fileStore;
  final ZbfReader _reader;
  final DensityService _density;

  final _log = logging.Logger('MarmotLibraryRepository');
  final _controller = StreamController<List<LibraryBook>>.broadcast();

  List<LibraryBook> _books = const [];
  bool _loaded = false;
  Future<void>? _loading;

  @override
  Stream<List<LibraryBook>> watchBooks() {
    unawaited(_ensureLoaded());
    if (_loaded) scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<LibraryBook?> getBook(String id) async {
    await _ensureLoaded();
    final cached = _find(id);
    if (cached != null) return cached;
    return _datasource.getBook(id);
  }

  @override
  Future<LibraryBook?> findByContentHash(String contentHash) async {
    await _ensureLoaded();
    for (final book in _books) {
      if (book.contentHash == contentHash) return book;
    }
    return null;
  }

  @override
  Future<LibraryBook> addBookFromIngestion(
    ZbfBook book,
    String zbfPath, {
    String? contentHash,
  }) async {
    await _ensureLoaded();
    final added = await _datasource.addBook(book, contentHash: contentHash);
    unawaited(_density.precalc(added.id, book));
    _upsert(added);
    return added;
  }

  @override
  Future<LibraryBook> indexExisting(String zbfPath) async {
    final handle = await _reader.open(zbfPath);
    final manifest = handle.manifest;
    final added = await _datasource.importExisting(
      manifest: manifest,
      coverBytes: _asset(handle, manifest.coverAsset),
    );
    _upsert(added);
    return added;
  }

  @override
  Future<void> deleteBook(String id) async {
    await _datasource.deleteBook(id);
    _books = _books.where((book) => book.id != id).toList(growable: false);
    _emit();
  }

  @override
  Future<void> touchOpened(String id) async {
    final now = DateTime.now();
    await _datasource.sendProgress(id, now);
    _books = _books
        .map((book) =>
            book.id == id ? book.copyWith(lastOpenedAt: now) : book)
        .toList(growable: false);
    _emit();
  }

  @override
  Future<List<ShareSkip>> shareBook(String id, String memberNpub) =>
      shareBookWith(id, [memberNpub]);

  @override
  Future<List<ShareSkip>> shareBookWith(String id, List<String> memberNpubs) async {
    final skipped = await _datasource.shareBookWith(id, memberNpubs);
    final added = memberNpubs.length - skipped.length;
    if (added > 0) {
      _books = _books
          .map((book) => book.id == id
              ? book.copyWith(memberCount: book.memberCount + added)
              : book)
          .toList(growable: false);
      _emit();
    }
    return skipped;
  }

  @override
  Future<LibraryBook> updateBookMetadata(
    String id, {
    required String title,
    String? author,
    String? genre,
    Uint8List? coverImage,
  }) async {
    await _ensureLoaded();
    final existing = _find(id);
    if (existing == null) {
      throw StateError('Book $id not found');
    }

    final cleanTitle = title.trim().isEmpty ? 'Untitled' : title.trim();
    final cleanAuthor = (author ?? '').trim();
    final cleanGenre = (genre ?? '').trim().isEmpty ? null : genre!.trim();

    final zbf = await _fileStore.zbfFile(id);
    if (zbf.existsSync()) {
      await _rewriteManifest(
        zbfPath: zbf.path,
        title: cleanTitle,
        author: cleanAuthor,
        genre: cleanGenre,
        coverImage: coverImage,
      );
    }

    var coverPath = existing.coverPath;
    if (coverImage != null) {
      coverPath = await _fileStore.writeCover(id, coverImage);
    }

    final current = await _datasource.currentMeta(id);
    if (current != null) {
      await _datasource.sendMeta(
        id,
        current.copyWith(
          title: cleanTitle,
          author: cleanAuthor,
          genre: cleanGenre,
        ),
      );
    }

    final updated = existing.copyWith(
      title: cleanTitle,
      author: cleanAuthor,
      genre: cleanGenre,
      coverPath: coverPath,
    );
    _upsert(updated);
    return updated;
  }

  @override
  Future<void> backfill() async {
    await _ensureLoaded();
    final known = _books.map((book) => book.id).toSet();
    for (final bookId in await _fileStore.listBookIds()) {
      if (known.contains(bookId)) continue;
      final zbf = await _fileStore.zbfFile(bookId);
      if (!zbf.existsSync()) continue;
      try {
        final handle = await _reader.open(zbf.path);
        final manifest = handle.manifest;
        final added = await _datasource.importExisting(
          manifest: manifest,
          coverBytes: _asset(handle, manifest.coverAsset),
        );
        _upsert(added, emit: false);
      } on Object catch (error, stack) {
        _log.warning('Backfill failed for $bookId', error, stack);
      }
    }
    _emit();
  }

  @override
  Future<List<String>> bookMembers(String id) async {
    final members = await _datasource.members(id);
    return members.map((member) => member.npub).toList(growable: false);
  }

  @override
  Future<List<String>> bookAdmins(String id) => _datasource.adminNpubs(id);

  @override
  Future<void> removeBookMember(String id, String memberNpub) async {
    await _datasource.removeMember(id, memberNpub);
    _books = _books
        .map((book) => book.id == id
            ? book.copyWith(
                memberCount: book.memberCount > 1 ? book.memberCount - 1 : 1)
            : book)
        .toList(growable: false);
    _emit();
  }

  @override
  Future<void> leaveCircle(String id) async {
    await _datasource.leaveCircle(id);
    _books = _books.where((book) => book.id != id).toList(growable: false);
    _emit();
  }

  @override
  Future<void> dissolveCircle(String id) async {
    await _datasource.dissolveCircle(id);
    _books = _books
        .map((book) => book.id == id ? book.copyWith(memberCount: 1) : book)
        .toList(growable: false);
    _emit();
  }

  @override
  Future<void> refresh() => _load();

  Future<void> _ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final books = await _datasource.loadLibrary();
    books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    _books = books;
    _loaded = true;
    _emit();
    unawaited(_ensureContent());
  }

  Future<void> _ensureContent() async {
    for (final book in List<LibraryBook>.from(_books)) {
      if (book.coverPath == null) {
        final coverPath = await _datasource.hydrateCover(book.id);
        if (coverPath != null) _patchCover(book.id, coverPath);
      }
      if (await _fileStore.hasZbf(book.id)) continue;
      final ok = await _datasource.downloadBookContent(book.id);
      if (!ok) continue;
      final coverPath = await _fileStore.coverPathIfExists(book.id);
      if (coverPath != null) _patchCover(book.id, coverPath);
    }
  }

  void _patchCover(String id, String coverPath) {
    _books = _books
        .map((b) => b.id == id ? b.copyWith(coverPath: coverPath) : b)
        .toList(growable: false);
    _emit();
  }

  void _upsert(LibraryBook book, {bool emit = true}) {
    _books = [
      book,
      ..._books.where((existing) => existing.id != book.id),
    ];
    if (emit) _emit();
  }

  LibraryBook? _find(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Uint8List? _asset(ZbfBookHandle handle, String name) {
    final bytes = handle.asset(name);
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_books));
    }
  }

  Future<void> _rewriteManifest({
    required String zbfPath,
    required String title,
    required String author,
    required String? genre,
    Uint8List? coverImage,
  }) async {
    final file = File(zbfPath);
    final source = ZipDecoder().decodeBytes(await file.readAsBytes());
    final manifest = BookManifest.fromJson(
      jsonDecode(utf8.decode(source.findFile('manifest.json')!.content))
          as Map<String, Object?>,
    ).copyWith(title: title, author: author, genre: genre);
    final coverAsset = manifest.coverAsset;

    final output = Archive();
    for (final entry in source.files) {
      if (entry.name == 'manifest.json') continue;
      if (coverImage != null && entry.name == coverAsset) continue;
      output.addFile(ArchiveFile(entry.name, entry.size, entry.content));
    }
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    output.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    if (coverImage != null) {
      output.addFile(ArchiveFile(coverAsset, coverImage.length, coverImage));
    }
    await file.writeAsBytes(ZipEncoder().encodeBytes(output), flush: true);
  }
}
