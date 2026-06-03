// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceFormatMeta = const VerificationMeta(
    'sourceFormat',
  );
  @override
  late final GeneratedColumn<String> sourceFormat = GeneratedColumn<String>(
    'source_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterCountMeta = const VerificationMeta(
    'chapterCount',
  );
  @override
  late final GeneratedColumn<int> chapterCount = GeneratedColumn<int>(
    'chapter_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zbfPathMeta = const VerificationMeta(
    'zbfPath',
  );
  @override
  late final GeneratedColumn<String> zbfPath = GeneratedColumn<String>(
    'zbf_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsAiProcessingMeta = const VerificationMeta(
    'needsAiProcessing',
  );
  @override
  late final GeneratedColumn<bool> needsAiProcessing = GeneratedColumn<bool>(
    'needs_ai_processing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_ai_processing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _zbfVersionMeta = const VerificationMeta(
    'zbfVersion',
  );
  @override
  late final GeneratedColumn<String> zbfVersion = GeneratedColumn<String>(
    'zbf_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    genre,
    contentHash,
    sourceFormat,
    pageCount,
    chapterCount,
    zbfPath,
    coverPath,
    needsAiProcessing,
    zbfVersion,
    createdAt,
    addedAt,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('source_format')) {
      context.handle(
        _sourceFormatMeta,
        sourceFormat.isAcceptableOrUnknown(
          data['source_format']!,
          _sourceFormatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceFormatMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pageCountMeta);
    }
    if (data.containsKey('chapter_count')) {
      context.handle(
        _chapterCountMeta,
        chapterCount.isAcceptableOrUnknown(
          data['chapter_count']!,
          _chapterCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterCountMeta);
    }
    if (data.containsKey('zbf_path')) {
      context.handle(
        _zbfPathMeta,
        zbfPath.isAcceptableOrUnknown(data['zbf_path']!, _zbfPathMeta),
      );
    } else if (isInserting) {
      context.missing(_zbfPathMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('needs_ai_processing')) {
      context.handle(
        _needsAiProcessingMeta,
        needsAiProcessing.isAcceptableOrUnknown(
          data['needs_ai_processing']!,
          _needsAiProcessingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_needsAiProcessingMeta);
    }
    if (data.containsKey('zbf_version')) {
      context.handle(
        _zbfVersionMeta,
        zbfVersion.isAcceptableOrUnknown(data['zbf_version']!, _zbfVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_zbfVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      sourceFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_format'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      chapterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_count'],
      )!,
      zbfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zbf_path'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      needsAiProcessing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_ai_processing'],
      )!,
      zbfVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zbf_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String id;
  final String title;
  final String author;
  final String? genre;
  final String? contentHash;
  final String sourceFormat;
  final int pageCount;
  final int chapterCount;
  final String zbfPath;
  final String? coverPath;
  final bool needsAiProcessing;
  final String zbfVersion;
  final DateTime createdAt;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  const BookRow({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    this.contentHash,
    required this.sourceFormat,
    required this.pageCount,
    required this.chapterCount,
    required this.zbfPath,
    this.coverPath,
    required this.needsAiProcessing,
    required this.zbfVersion,
    required this.createdAt,
    required this.addedAt,
    this.lastOpenedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    map['source_format'] = Variable<String>(sourceFormat);
    map['page_count'] = Variable<int>(pageCount);
    map['chapter_count'] = Variable<int>(chapterCount);
    map['zbf_path'] = Variable<String>(zbfPath);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['needs_ai_processing'] = Variable<bool>(needsAiProcessing);
    map['zbf_version'] = Variable<String>(zbfVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      sourceFormat: Value(sourceFormat),
      pageCount: Value(pageCount),
      chapterCount: Value(chapterCount),
      zbfPath: Value(zbfPath),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      needsAiProcessing: Value(needsAiProcessing),
      zbfVersion: Value(zbfVersion),
      createdAt: Value(createdAt),
      addedAt: Value(addedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      genre: serializer.fromJson<String?>(json['genre']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      sourceFormat: serializer.fromJson<String>(json['sourceFormat']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      chapterCount: serializer.fromJson<int>(json['chapterCount']),
      zbfPath: serializer.fromJson<String>(json['zbfPath']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      needsAiProcessing: serializer.fromJson<bool>(json['needsAiProcessing']),
      zbfVersion: serializer.fromJson<String>(json['zbfVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'genre': serializer.toJson<String?>(genre),
      'contentHash': serializer.toJson<String?>(contentHash),
      'sourceFormat': serializer.toJson<String>(sourceFormat),
      'pageCount': serializer.toJson<int>(pageCount),
      'chapterCount': serializer.toJson<int>(chapterCount),
      'zbfPath': serializer.toJson<String>(zbfPath),
      'coverPath': serializer.toJson<String?>(coverPath),
      'needsAiProcessing': serializer.toJson<bool>(needsAiProcessing),
      'zbfVersion': serializer.toJson<String>(zbfVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
    };
  }

  BookRow copyWith({
    String? id,
    String? title,
    String? author,
    Value<String?> genre = const Value.absent(),
    Value<String?> contentHash = const Value.absent(),
    String? sourceFormat,
    int? pageCount,
    int? chapterCount,
    String? zbfPath,
    Value<String?> coverPath = const Value.absent(),
    bool? needsAiProcessing,
    String? zbfVersion,
    DateTime? createdAt,
    DateTime? addedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
  }) => BookRow(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    genre: genre.present ? genre.value : this.genre,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    sourceFormat: sourceFormat ?? this.sourceFormat,
    pageCount: pageCount ?? this.pageCount,
    chapterCount: chapterCount ?? this.chapterCount,
    zbfPath: zbfPath ?? this.zbfPath,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    needsAiProcessing: needsAiProcessing ?? this.needsAiProcessing,
    zbfVersion: zbfVersion ?? this.zbfVersion,
    createdAt: createdAt ?? this.createdAt,
    addedAt: addedAt ?? this.addedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      genre: data.genre.present ? data.genre.value : this.genre,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      sourceFormat: data.sourceFormat.present
          ? data.sourceFormat.value
          : this.sourceFormat,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      chapterCount: data.chapterCount.present
          ? data.chapterCount.value
          : this.chapterCount,
      zbfPath: data.zbfPath.present ? data.zbfPath.value : this.zbfPath,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      needsAiProcessing: data.needsAiProcessing.present
          ? data.needsAiProcessing.value
          : this.needsAiProcessing,
      zbfVersion: data.zbfVersion.present
          ? data.zbfVersion.value
          : this.zbfVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('genre: $genre, ')
          ..write('contentHash: $contentHash, ')
          ..write('sourceFormat: $sourceFormat, ')
          ..write('pageCount: $pageCount, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('zbfPath: $zbfPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('needsAiProcessing: $needsAiProcessing, ')
          ..write('zbfVersion: $zbfVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    genre,
    contentHash,
    sourceFormat,
    pageCount,
    chapterCount,
    zbfPath,
    coverPath,
    needsAiProcessing,
    zbfVersion,
    createdAt,
    addedAt,
    lastOpenedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.genre == this.genre &&
          other.contentHash == this.contentHash &&
          other.sourceFormat == this.sourceFormat &&
          other.pageCount == this.pageCount &&
          other.chapterCount == this.chapterCount &&
          other.zbfPath == this.zbfPath &&
          other.coverPath == this.coverPath &&
          other.needsAiProcessing == this.needsAiProcessing &&
          other.zbfVersion == this.zbfVersion &&
          other.createdAt == this.createdAt &&
          other.addedAt == this.addedAt &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> author;
  final Value<String?> genre;
  final Value<String?> contentHash;
  final Value<String> sourceFormat;
  final Value<int> pageCount;
  final Value<int> chapterCount;
  final Value<String> zbfPath;
  final Value<String?> coverPath;
  final Value<bool> needsAiProcessing;
  final Value<String> zbfVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.genre = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.sourceFormat = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.zbfPath = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.needsAiProcessing = const Value.absent(),
    this.zbfVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String title,
    required String author,
    this.genre = const Value.absent(),
    this.contentHash = const Value.absent(),
    required String sourceFormat,
    required int pageCount,
    required int chapterCount,
    required String zbfPath,
    this.coverPath = const Value.absent(),
    required bool needsAiProcessing,
    required String zbfVersion,
    required DateTime createdAt,
    required DateTime addedAt,
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       author = Value(author),
       sourceFormat = Value(sourceFormat),
       pageCount = Value(pageCount),
       chapterCount = Value(chapterCount),
       zbfPath = Value(zbfPath),
       needsAiProcessing = Value(needsAiProcessing),
       zbfVersion = Value(zbfVersion),
       createdAt = Value(createdAt),
       addedAt = Value(addedAt);
  static Insertable<BookRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? genre,
    Expression<String>? contentHash,
    Expression<String>? sourceFormat,
    Expression<int>? pageCount,
    Expression<int>? chapterCount,
    Expression<String>? zbfPath,
    Expression<String>? coverPath,
    Expression<bool>? needsAiProcessing,
    Expression<String>? zbfVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (genre != null) 'genre': genre,
      if (contentHash != null) 'content_hash': contentHash,
      if (sourceFormat != null) 'source_format': sourceFormat,
      if (pageCount != null) 'page_count': pageCount,
      if (chapterCount != null) 'chapter_count': chapterCount,
      if (zbfPath != null) 'zbf_path': zbfPath,
      if (coverPath != null) 'cover_path': coverPath,
      if (needsAiProcessing != null) 'needs_ai_processing': needsAiProcessing,
      if (zbfVersion != null) 'zbf_version': zbfVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (addedAt != null) 'added_at': addedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? author,
    Value<String?>? genre,
    Value<String?>? contentHash,
    Value<String>? sourceFormat,
    Value<int>? pageCount,
    Value<int>? chapterCount,
    Value<String>? zbfPath,
    Value<String?>? coverPath,
    Value<bool>? needsAiProcessing,
    Value<String>? zbfVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      contentHash: contentHash ?? this.contentHash,
      sourceFormat: sourceFormat ?? this.sourceFormat,
      pageCount: pageCount ?? this.pageCount,
      chapterCount: chapterCount ?? this.chapterCount,
      zbfPath: zbfPath ?? this.zbfPath,
      coverPath: coverPath ?? this.coverPath,
      needsAiProcessing: needsAiProcessing ?? this.needsAiProcessing,
      zbfVersion: zbfVersion ?? this.zbfVersion,
      createdAt: createdAt ?? this.createdAt,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (sourceFormat.present) {
      map['source_format'] = Variable<String>(sourceFormat.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (chapterCount.present) {
      map['chapter_count'] = Variable<int>(chapterCount.value);
    }
    if (zbfPath.present) {
      map['zbf_path'] = Variable<String>(zbfPath.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (needsAiProcessing.present) {
      map['needs_ai_processing'] = Variable<bool>(needsAiProcessing.value);
    }
    if (zbfVersion.present) {
      map['zbf_version'] = Variable<String>(zbfVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('genre: $genre, ')
          ..write('contentHash: $contentHash, ')
          ..write('sourceFormat: $sourceFormat, ')
          ..write('pageCount: $pageCount, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('zbfPath: $zbfPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('needsAiProcessing: $needsAiProcessing, ')
          ..write('zbfVersion: $zbfVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDatabase extends GeneratedDatabase {
  _$LibraryDatabase(QueryExecutor e) : super(e);
  $LibraryDatabaseManager get managers => $LibraryDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final Index idxBooksAddedAt = Index(
    'idx_books_added_at',
    'CREATE INDEX idx_books_added_at ON books (added_at)',
  );
  late final Index idxBooksContentHash = Index(
    'idx_books_content_hash',
    'CREATE INDEX idx_books_content_hash ON books (content_hash)',
  );
  late final BooksDao booksDao = BooksDao(this as LibraryDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    idxBooksAddedAt,
    idxBooksContentHash,
  ];
}

typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      required String id,
      required String title,
      required String author,
      Value<String?> genre,
      Value<String?> contentHash,
      required String sourceFormat,
      required int pageCount,
      required int chapterCount,
      required String zbfPath,
      Value<String?> coverPath,
      required bool needsAiProcessing,
      required String zbfVersion,
      required DateTime createdAt,
      required DateTime addedAt,
      Value<DateTime?> lastOpenedAt,
      Value<int> rowid,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> author,
      Value<String?> genre,
      Value<String?> contentHash,
      Value<String> sourceFormat,
      Value<int> pageCount,
      Value<int> chapterCount,
      Value<String> zbfPath,
      Value<String?> coverPath,
      Value<bool> needsAiProcessing,
      Value<String> zbfVersion,
      Value<DateTime> createdAt,
      Value<DateTime> addedAt,
      Value<DateTime?> lastOpenedAt,
      Value<int> rowid,
    });

class $$BooksTableFilterComposer
    extends Composer<_$LibraryDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFormat => $composableBuilder(
    column: $table.sourceFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zbfPath => $composableBuilder(
    column: $table.zbfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsAiProcessing => $composableBuilder(
    column: $table.needsAiProcessing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zbfVersion => $composableBuilder(
    column: $table.zbfVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$LibraryDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFormat => $composableBuilder(
    column: $table.sourceFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zbfPath => $composableBuilder(
    column: $table.zbfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsAiProcessing => $composableBuilder(
    column: $table.needsAiProcessing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zbfVersion => $composableBuilder(
    column: $table.zbfVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFormat => $composableBuilder(
    column: $table.sourceFormat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zbfPath =>
      $composableBuilder(column: $table.zbfPath, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<bool> get needsAiProcessing => $composableBuilder(
    column: $table.needsAiProcessing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zbfVersion => $composableBuilder(
    column: $table.zbfVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, BaseReferences<_$LibraryDatabase, $BooksTable, BookRow>),
          BookRow,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$LibraryDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<String> sourceFormat = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> chapterCount = const Value.absent(),
                Value<String> zbfPath = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<bool> needsAiProcessing = const Value.absent(),
                Value<String> zbfVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                author: author,
                genre: genre,
                contentHash: contentHash,
                sourceFormat: sourceFormat,
                pageCount: pageCount,
                chapterCount: chapterCount,
                zbfPath: zbfPath,
                coverPath: coverPath,
                needsAiProcessing: needsAiProcessing,
                zbfVersion: zbfVersion,
                createdAt: createdAt,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String author,
                Value<String?> genre = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                required String sourceFormat,
                required int pageCount,
                required int chapterCount,
                required String zbfPath,
                Value<String?> coverPath = const Value.absent(),
                required bool needsAiProcessing,
                required String zbfVersion,
                required DateTime createdAt,
                required DateTime addedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                author: author,
                genre: genre,
                contentHash: contentHash,
                sourceFormat: sourceFormat,
                pageCount: pageCount,
                chapterCount: chapterCount,
                zbfPath: zbfPath,
                coverPath: coverPath,
                needsAiProcessing: needsAiProcessing,
                zbfVersion: zbfVersion,
                createdAt: createdAt,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, BaseReferences<_$LibraryDatabase, $BooksTable, BookRow>),
      BookRow,
      PrefetchHooks Function()
    >;

class $LibraryDatabaseManager {
  final _$LibraryDatabase _db;
  $LibraryDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
}

mixin _$BooksDaoMixin on DatabaseAccessor<LibraryDatabase> {
  $BooksTable get books => attachedDatabase.books;
  BooksDaoManager get managers => BooksDaoManager(this);
}

class BooksDaoManager {
  final _$BooksDaoMixin _db;
  BooksDaoManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db.attachedDatabase, _db.books);
}
