import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class IngestionPageState extends Equatable {
  const IngestionPageState();

  @override
  List<Object?> get props => [];
}

class IngestionPageIdle extends IngestionPageState {
  const IngestionPageIdle();
}

class IngestionPagePicking extends IngestionPageState {
  const IngestionPagePicking();
}

class IngestionPageFilePicked extends IngestionPageState {
  const IngestionPageFilePicked(this.file, this.rawTitle, this.contentHash);

  final File file;
  final String rawTitle;
  final String contentHash;

  @override
  List<Object?> get props => [file.path, rawTitle, contentHash];
}

class IngestionPageError extends IngestionPageState {
  const IngestionPageError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
