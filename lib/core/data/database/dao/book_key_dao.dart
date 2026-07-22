import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class BookKeyDao {
  final FlutterSecureStorage _storage;

  BookKeyDao() : _storage = const FlutterSecureStorage();

  String _keyFor(String circleDirId) => 'book_key_$circleDirId';
  String _ivFor(String circleDirId) => 'book_iv_$circleDirId';

  Future<void> saveKey({
    required String nostrGroupId,
    required String circleDirId,
    required String keyHex,
    required String ivHex,
  }) async {
    await _storage.write(key: _keyFor(circleDirId), value: keyHex);
    await _storage.write(key: _ivFor(circleDirId), value: ivHex);
  }

  Future<({String keyHex, String ivHex})?> getKey(String circleDirId) async {
    final key = await _storage.read(key: _keyFor(circleDirId));
    final iv = await _storage.read(key: _ivFor(circleDirId));
    if (key != null && iv != null) {
      return (keyHex: key, ivHex: iv);
    }
    return null;
  }
}
