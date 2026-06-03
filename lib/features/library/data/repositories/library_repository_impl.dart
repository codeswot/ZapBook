import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:zapbook/features/book_ingestion/data/documents_directory.dart';
import 'package:zapbook/features/library/data/cover/cover_store.dart';
import 'package:zapbook/features/library/data/db/library_database.dart';
import 'package:zapbook/features/library/domain/entities/library_book.dart';
import 'package:zapbook/features/library/domain/repositories/library_repository.dart';
import 'package:zapbook/zbf/zbf.dart';

@LazySingleton(as: LibraryRepository)
final class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(
    this._database,
    this._coverStore,
    this._documentsDirectory,
    this._reader,
  );

  final LibraryDatabase _database;
  final CoverStore _coverStore;
  final DocumentsDirectory _documentsDirectory;
  final ZbfReader _reader;

  BooksDao get _dao => _database.booksDao;

  @override
  Stream<List<LibraryBook>> watchBooks() {
    return _dao.watchAll().map(
      (rows) => rows.map(_toEntity).toList(growable: false),
    );
  }

  @override
  Future<LibraryBook?> getBook(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<LibraryBook?> findByContentHash(String contentHash) async {
    final row = await _dao.getByContentHash(contentHash);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<LibraryBook> addBookFromIngestion(
    ZbfBook book,
    String zbfPath, {
    String? contentHash,
  }) {
    final manifest = book.manifest;
    final coverBytes = book.assets[manifest.coverAsset];
    return _index(manifest, zbfPath, coverBytes, contentHash: contentHash);
  }

  @override
  Future<LibraryBook> indexExisting(String zbfPath) async {
    final handle = await _reader.open(zbfPath);
    final manifest = handle.manifest;
    final coverBytes = handle.asset(manifest.coverAsset);
    return _index(manifest, zbfPath, coverBytes);
  }

  @override
  Future<void> deleteBook(String id) async {
    final row = await _dao.getById(id);
    if (row == null) {
      return;
    }
    final zbf = File(row.zbfPath);
    if (zbf.existsSync()) {
      await zbf.delete();
    }
    await _coverStore.deleteCover(row.coverPath);
    await _dao.deleteById(id);
  }

  @override
  Future<void> touchOpened(String id) {
    return _dao.touchOpened(id, DateTime.now());
  }

  @override
  Future<void> backfill() async {
    final directory = await _documentsDirectory.resolve();
    if (!directory.existsSync()) {
      return;
    }
    final indexed = (await _dao.allZbfPaths()).toSet();
    for (final entity in directory.listSync()) {
      final isZbf =
          entity is File && entity.path.toLowerCase().endsWith('.zbf');
      if (isZbf && !indexed.contains(entity.path)) {
        await indexExisting(entity.path);
      }
    }
  }

  @override
  Future<LibraryBook> updateBookMetadata(
    String id, {
    required String title,
    String? author,
    String? genre,
    Uint8List? coverImage,
  }) async {
    final row = await _dao.getById(id);
    if (row == null) {
      throw StateError('Book $id not found');
    }
    final cleanTitle = title.trim().isEmpty ? 'Untitled' : title.trim();
    final cleanAuthor = (author ?? '').trim();
    final cleanGenre = (genre ?? '').trim().isEmpty ? null : genre!.trim();

    await _rewriteManifest(
      zbfPath: row.zbfPath,
      title: cleanTitle,
      author: cleanAuthor,
      genre: cleanGenre,
      coverImage: coverImage,
    );

    var coverPath = row.coverPath;
    if (coverImage != null) {
      coverPath = await _coverStore.writeCover(id, coverImage);
    }

    await _dao.updateMetadata(
      id,
      title: cleanTitle,
      author: cleanAuthor,
      genre: cleanGenre,
      coverPath: coverPath,
    );
    final updated = await _dao.getById(id);
    return _toEntity(updated!);
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
      if (entry.name == 'manifest.json') {
        continue;
      }
      if (coverImage != null && entry.name == coverAsset) {
        continue;
      }
      output.addFile(ArchiveFile(entry.name, entry.size, entry.content));
    }
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    output.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    if (coverImage != null) {
      output.addFile(
        ArchiveFile(coverAsset, coverImage.length, coverImage),
      );
    }
    await file.writeAsBytes(ZipEncoder().encodeBytes(output), flush: true);
  }

  Future<LibraryBook> _index(
    BookManifest manifest,
    String zbfPath,
    List<int>? coverBytes, {
    String? contentHash,
  }) async {
    final coverPath = await _coverStore.writeCover(
      manifest.id,
      coverBytes == null ? null : Uint8List.fromList(coverBytes),
    );
    await _dao.upsert(
      BooksCompanion.insert(
        id: manifest.id,
        title: manifest.title,
        author: manifest.author,
        genre: Value(manifest.genre),
        contentHash: Value(contentHash),
        sourceFormat: manifest.sourceFormat.wireValue,
        pageCount: manifest.pageCount,
        chapterCount: manifest.chapterCount,
        zbfPath: zbfPath,
        coverPath: Value(coverPath),
        needsAiProcessing: manifest.needsAiProcessing,
        zbfVersion: manifest.zbfVersion,
        createdAt: manifest.createdAt,
        addedAt: DateTime.now(),
      ),
    );
    final row = await _dao.getById(manifest.id);
    return _toEntity(row!);
  }

  LibraryBook _toEntity(BookRow row) {
    return LibraryBook(
      id: row.id,
      title: row.title,
      author: row.author,
      genre: row.genre,
      sourceFormat: BookSourceFormat.fromWire(row.sourceFormat),
      pageCount: row.pageCount,
      chapterCount: row.chapterCount,
      zbfPath: row.zbfPath,
      coverPath: row.coverPath,
      needsAiProcessing: row.needsAiProcessing,
      zbfVersion: row.zbfVersion,
      createdAt: row.createdAt,
      addedAt: row.addedAt,
      lastOpenedAt: row.lastOpenedAt,
      contentHash: row.contentHash,
    );
  }
}
