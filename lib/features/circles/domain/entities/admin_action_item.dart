import 'package:equatable/equatable.dart';

import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/core/domain/entities/pending_circle_upload.dart';

final class AdminActionItem extends Equatable {
  const AdminActionItem({
    required this.book,
    this.pendingUpload,
    this.reseedRequesterNpubs = const [],
  });

  final CircleBook book;
  final PendingCircleUpload? pendingUpload;
  final List<String> reseedRequesterNpubs;

  bool get hasFailedUpload => pendingUpload != null;
  bool get hasReseedRequests => reseedRequesterNpubs.isNotEmpty;

  @override
  List<Object?> get props => [book, pendingUpload, reseedRequesterNpubs];
}
