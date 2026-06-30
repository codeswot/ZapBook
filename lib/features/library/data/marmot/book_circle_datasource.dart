import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart' as logging;
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/features/library/data/marmot/book_payloads.dart';
import 'package:zapbook/core/domain/entities/circle_book.dart';
import 'package:zapbook/zbf/zbf.dart';

@lazySingleton
class BookCircleDatasource {
  BookCircleDatasource();

  final _log = logging.Logger('BookCircleDatasource');

  Future<CircleBook> addBookCircle(ZbfBook book, {String? contentHash}) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<CircleBook> importExisting({
    required BookManifest manifest,
    Uint8List? coverBytes,
    String? contentHash,
  }) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<void> deleteCircle(String circleId) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<void> leaveCircle(String circleId) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<void> dissolveCircle(String circleId) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<List<MarmotMember>> members(String circleId) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<List<String>> adminNpubs(String circleId) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<void> removeMember(String circleId, String memberNpub) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<List<String>> shareBookCircleWith(
    String circleId,
    List<String> npubs,
  ) async {
    throw UnimplementedError('To be implemented step-by-step');
  }

  Future<BookMetaPayload?> currentMeta(String circleId) async {
    return null; // Stubbed, using description now
  }

  Future<void> sendMeta(String circleId, BookMetaPayload meta) async {
    // Stubbed
  }

  Future<void> sendProgress(String circleId, DateTime lastReadAt) async {
    // Stubbed
  }

  Future<String?> hydrateCover(String circleId) async {
    return null; // Stubbed
  }

  Future<bool> downloadBookContent(String circleId) async {
    return false; // Stubbed
  }
}
