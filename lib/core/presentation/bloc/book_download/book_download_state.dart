import 'package:equatable/equatable.dart';

class BookDownloadState extends Equatable {
  const BookDownloadState({
    this.downloadingBookIds = const {},
    this.downloadProgress = const {},
    this.errorMessage,
  });

  final Set<String> downloadingBookIds;
  final Map<String, int> downloadProgress;
  final String? errorMessage;

  BookDownloadState copyWith({
    Set<String>? downloadingBookIds,
    Map<String, int>? downloadProgress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookDownloadState(
      downloadingBookIds: downloadingBookIds ?? this.downloadingBookIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [downloadingBookIds, downloadProgress, errorMessage];
}
