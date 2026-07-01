import 'dart:convert';
import 'package:injectable/injectable.dart';
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
  final _groupHashes = <String, int>{};
  final _lastSeenBooks = <String, CircleBook>{};

  Stream<List<CircleBook>> get watchCircleBooks => _circlesController.stream;
  List<CircleBook> get currentCircles => _circlesController.value;

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
    _groupStore.watchGroups.listen((groups) async {
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

        if (lastHash != null && lastHash == currentHash && lastBook != null) {
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

          final zbf = await _fileStore.zbfFile(g.nostrGroupId);

          String? coverPath;
          if (g.imageHash != null) {
            coverPath = (await _fileStore.coverFile(g.nostrGroupId)).path;
          } else {
            coverPath = await _fileStore.coverPathIfExists(g.nostrGroupId);
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
      _circlesController.add(books);
    });
  }

  // create ~ here

  // update

  Future<void> deleteCircleBook(CircleBook circleBook) async {
    await _groupStore.deleteGroup(circleBook.id);
    await _fileStore.deleteBook(circleBook.nostrGroudId);
  }
}
