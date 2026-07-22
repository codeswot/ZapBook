class BookManifestPayload {
  final String circleDirId;
  final String keyHex;
  final String ivHex;
  final BookManifestFile? source;
  final List<BookManifestSegment> segments;

  const BookManifestPayload({
    required this.circleDirId,
    required this.keyHex,
    required this.ivHex,
    required this.segments,
    this.source,
  });

  factory BookManifestPayload.fromJson(Map<String, dynamic> json) {
    return BookManifestPayload(
      circleDirId: json['circleDirId'] as String,
      keyHex: json['keyHex'] as String,
      ivHex: json['ivHex'] as String,
      source: json['source'] != null
          ? BookManifestFile.fromJson(json['source'] as Map<String, dynamic>)
          : null,
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map(
                (e) => BookManifestSegment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'circleDirId': circleDirId,
      'keyHex': keyHex,
      'ivHex': ivHex,
      'source': source?.toJson(),
      'segments': segments.map((e) => e.toJson()).toList(),
    };
  }
}

class BookManifestFile {
  final String url;
  final String hash;
  final String filename;
  final String mimeType;

  const BookManifestFile({
    required this.url,
    required this.hash,
    required this.filename,
    required this.mimeType,
  });

  factory BookManifestFile.fromJson(Map<String, dynamic> json) {
    return BookManifestFile(
      url: json['url'] as String,
      hash: json['hash'] as String,
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'hash': hash,
      'filename': filename,
      'mimeType': mimeType,
    };
  }
}

class BookManifestSegment {
  final int index;
  final BookManifestFile file;

  const BookManifestSegment({required this.index, required this.file});

  factory BookManifestSegment.fromJson(Map<String, dynamic> json) {
    return BookManifestSegment(
      index: json['index'] as int,
      file: BookManifestFile.fromJson(json['file'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'index': index, 'file': file.toJson()};
  }
}
