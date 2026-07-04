import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:flutter/painting.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zapbook/core/data/library_file_store.dart';
import 'package:zapbook/core/domain/book_group_naming.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/services/group_store_service.dart';
import 'package:zapbook/zbf/enums/book_source_format.dart';
import 'package:logging/logging.dart' as logging;

@lazySingleton
class CircleStoreService {
  CircleStoreService(this._groupStore, this._fileStore) {
    _init();
  }
  final _log = logging.Logger('CircleStoreService');

  final GroupStoreService _groupStore;
  final LibraryFileStore _fileStore;

  final _circlesController = BehaviorSubject<List<CircleBook>>.seeded([]);
  Stream<List<CircleBook>> get watchCircleBooks => _circlesController.stream;
  List<CircleBook> get currentCircles => _circlesController.value;

  StreamSubscription? _groupSubscription;

  final Map<String, int> _groupHashes = {};
  final Map<String, CircleBook> _lastSeenBooks = {};

  final BehaviorSubject<Map<String, String>> _uploadingCovers =
      BehaviorSubject.seeded({});
  Stream<Map<String, String>> get watchUploadingCovers =>
      _uploadingCovers.stream;
  Map<String, String> get currentUploadingCovers => _uploadingCovers.value;

  void setUploadingCover(String groupId, String blurhash) {
    final current = Map<String, String>.from(_uploadingCovers.value);
    current[groupId] = blurhash;
    _uploadingCovers.add(current);
  }

  void clearUploadingCover(String groupId) {
    final current = Map<String, String>.from(_uploadingCovers.value);
    current.remove(groupId);
    _uploadingCovers.add(current);
  }

  Stream<CircleBook?> get watchLastOpenedCircleBook =>
      watchCircleBooks.map((circleBooks) {
        CircleBook? latest;
        for (final circleBook in circleBooks) {
          if (circleBook.lastOpenedAt == null) continue;
          if (latest == null ||
              circleBook.lastOpenedAt!.isAfter(latest.lastOpenedAt!)) {
            latest = circleBook;
          }
        }
        return latest;
      }).distinct();

  void _init() {
    _groupSubscription = _groupStore.watchGroups
        .asyncMap((groups) async {
          final circles = groups
              .where((g) => BookGroupNaming.matches(g.name))
              .toList();

          final books = <CircleBook>[];
          final futures = <Future<void>>[];

          for (final g in circles) {
            final currentHash = Object.hash(
              g.name,
              g.description,
              g.memberCount,
              g.adminNpubs.join(','),
              g.imageHash != null ? String.fromCharCodes(g.imageHash!) : null,
              g.imageKey != null ? String.fromCharCodes(g.imageKey!) : null,
              g.imageNonce != null ? String.fromCharCodes(g.imageNonce!) : null,
            );
            final lastHash = _groupHashes[g.id];
            final lastBook = _lastSeenBooks[g.id];

            if (lastHash != null &&
                lastHash == currentHash &&
                lastBook != null) {
              books.add(lastBook);
              continue;
            }

            futures.add(() async {
              final title = BookGroupNaming.titleOf(g.name);
              final dirId = BookGroupNaming.circleDirIdOf(g.name);

              String? author;
              String? genre;
              String? sourceFormat;
              int? pageCount;
              int? chapterCount;
              String? zbfVersion;
              bool? needsAiProcessing;
              int? createdAtMs;
              int? addedAtMs;
              String? contentHash;

              if (g.description.isNotEmpty) {
                try {
                  final map = jsonDecode(g.description) as Map<String, dynamic>;
                  author = map['author'] as String?;
                  genre = map['genre'] as String?;
                  sourceFormat = map['sourceFormat'] as String?;
                  pageCount = (map['pageCount'] as num?)?.toInt();
                  chapterCount = (map['chapterCount'] as num?)?.toInt();
                  zbfVersion = map['zbfVersion'] as String?;
                  needsAiProcessing = map['needsAiProcessing'] as bool?;
                  createdAtMs = (map['createdAtMs'] as num?)?.toInt();
                  addedAtMs = (map['addedAtMs'] as num?)?.toInt();
                  contentHash = map['contentHash'] as String?;
                } catch (error, _) {
                  _log.info('Error parsing description (legacy)');
                }
              }

              final zbf = await _fileStore.zbfFile(dirId);

              String? coverPath;
              if (g.imageHash != null) {
                final hashHex = hex.encode(g.imageHash!);
                coverPath = await _fileStore.coverPathIfExists(
                  dirId,
                  imageHashHex: hashHex,
                );

                if (coverPath == null) {
                  _downloadGroupImage(
                    g.id,
                    dirId,
                    hashHex,
                    g.imageHash!,
                    g.imageKey,
                    g.imageNonce,
                  );
                }
              } else {
                coverPath = await _fileStore.coverPathIfExists(dirId);
              }
              final book = CircleBook(
                id: g.id,
                nostrGroudId: g.nostrGroupId,
                circleDirId: dirId,
                title: title,
                author: author ?? lastBook?.author ?? '',
                genre: genre ?? lastBook?.genre,
                memberCount: g.memberCount,
                addedAt: addedAtMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(addedAtMs)
                    : lastBook?.addedAt ?? DateTime.now(),
                lastOpenedAt: lastBook?.lastOpenedAt,
                coverPath: coverPath ?? lastBook?.coverPath,
                sourceFormat: BookSourceFormat.fromWire(
                  sourceFormat ?? lastBook?.sourceFormat.wireValue ?? 'pdf',
                ),
                pageCount: pageCount ?? lastBook?.pageCount ?? 0,
                chapterCount: chapterCount ?? lastBook?.chapterCount ?? 0,
                zbfPath: zbf.path,
                needsAiProcessing:
                    needsAiProcessing ?? lastBook?.needsAiProcessing ?? false,
                zbfVersion: zbfVersion ?? lastBook?.zbfVersion ?? '',
                createdAt: createdAtMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
                    : lastBook?.createdAt ?? DateTime.now(),
                contentHash: contentHash ?? lastBook?.contentHash,
                adminNpubs: g.adminNpubs,
              );
              books.add(book);
              _groupHashes[g.id] = currentHash;
              _lastSeenBooks[g.id] = book;
            }());
          }

          await Future.wait(futures);

          final currentIds = circles.map((g) => g.id).toSet();
          _groupHashes.removeWhere((id, _) => !currentIds.contains(id));
          _lastSeenBooks.removeWhere((id, _) => !currentIds.contains(id));

          books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
          return books;
        })
        .listen((books) {
          _circlesController.add(books);
        });
  }

  @disposeMethod
  void dispose() {
    _groupSubscription?.cancel();
    _circlesController.close();
    _uploadingCovers.close();
  }

  Future<void> _downloadGroupImage(
    String groupId,
    String dirId,
    String hashHex,
    Uint8List imageHash,
    Uint8List? imageKey,
    Uint8List? imageNonce,
  ) async {
    try {
      final bytes = await _groupStore.downloadImage(
        imageHash,
        imageKey,
        imageNonce,
      );
      if (bytes != null) {
        await _fileStore.writeCover(dirId, bytes, imageHashHex: hashHex);
        await refreshBookCover(dirId, imageHashHex: hashHex);
      }
    } catch (e, st) {
      _log.warning('Failed to download image for $groupId', e, st);
    }
  }

  Future<String> createCircleBook({
    required String circleDirId,
    required String humanTitle,
    required Map<String, dynamic> metadata,
    List<String> memberKeyPackageEventJsons = const [],
  }) async {
    final groupName = BookGroupNaming.nameFor(circleDirId, humanTitle);
    final groupDescription = jsonEncode(metadata);

    final cirlceGroup = await _groupStore.createGroup(
      name: groupName,
      description: groupDescription,
      memberKeyPackageEventJsons: memberKeyPackageEventJsons,
    );
    return cirlceGroup.id;
  }

  Future<void> updateCircleBookMetadata({
    required String marmotGroupId,
    String? author,
    String? genre,
    String? title,
  }) async {
    final group = _groupStore.currentGroups
        .where((g) => g.id == marmotGroupId)
        .firstOrNull;
    if (group == null) return;

    Map<String, dynamic> metadata = {};
    if (group.description.isNotEmpty) {
      try {
        metadata = Map<String, dynamic>.from(
          jsonDecode(group.description) as Map,
        );
      } catch (_) {}
    }

    bool changed = false;
    if (author != null && author.isNotEmpty && metadata['author'] != author) {
      metadata['author'] = author;
      changed = true;
    }
    if (genre != null && genre.isNotEmpty && metadata['genre'] != genre) {
      metadata['genre'] = genre;
      changed = true;
    }

    String? newName;
    if (title != null && title.isNotEmpty) {
      final circleDirId = BookGroupNaming.circleDirIdOf(group.name);
      final generatedName = BookGroupNaming.nameFor(circleDirId, title);
      if (generatedName != group.name) {
        newName = generatedName;
        changed = true;
      }
    }

    if (changed) {
      await _groupStore.updateGroupMetadata(
        groupId: marmotGroupId,
        name: newName,
        description: jsonEncode(metadata),
      );
    }
  }

  Future<GroupImagePrepared> prepareCover({
    required Uint8List coverBytes,
  }) async {
    return _groupStore.prepareImage(coverBytes);
  }

  void updateCircleBookCoverOptimistic({
    required String marmotGroupId,
    required String circleDirId,
    required Uint8List coverBytes,
    required GroupImagePrepared preparedImage,
    required String mimeType,
  }) {
    unawaited(() async {
      try {
        await _groupStore.uploadImage(preparedImage, mimeType);
        await _groupStore.setGroupImage(
          groupId: marmotGroupId,
          preparedImage: preparedImage,
        );

        final hashHex = hex.encode(preparedImage.imageHash);
        await _fileStore.writeCover(
          circleDirId,
          coverBytes,
          imageHashHex: hashHex,
        );
        await refreshBookCover(circleDirId, imageHashHex: hashHex);
      } catch (e, st) {
        _log.warning('Failed background cover upload & update', e, st);
      } finally {
        clearUploadingCover(marmotGroupId);
      }
    }());
  }

  Future<void> refreshBookCover(
    String circleDirId, {
    String? imageHashHex,
  }) async {
    final bookEntry = _lastSeenBooks.entries
        .where((e) => e.value.circleDirId == circleDirId)
        .firstOrNull;
    if (bookEntry != null) {
      final book = bookEntry.value;
      final coverPath = await _fileStore.coverPathIfExists(
        circleDirId,
        imageHashHex: imageHashHex,
      );
      if (coverPath != null) {
        if (book.coverPath != null && book.coverPath != coverPath) {
          await FileImage(File(book.coverPath!)).evict();
        }
        final updatedBook = book.copyWith(coverPath: coverPath);
        _lastSeenBooks[book.id] = updatedBook;

        final books = _lastSeenBooks.values.toList();
        books.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        _circlesController.add(books);
      }
    }
  }

  Future<void> deleteCircleBook(CircleBook circleBook) async {
    await _groupStore.deleteGroup(circleBook.id);
    await _fileStore.deleteBook(circleBook.circleDirId);
  }
}
