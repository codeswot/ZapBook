import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';

import 'package:zapbook/core/identity/account_paths.dart';

@module
abstract class MarmotModule {
  @preResolve
  @lazySingleton
  Future<Marmot> marmot() => MarmotWarmup.start();
}

final class MarmotWarmup {
  const MarmotWarmup._();

  static Future<Marmot>? _warm;

  static Future<Marmot> start() => _warm ??= _open();

  static void reset() => _warm = null;

  static Future<Marmot> _open() async {
    final dir = await AccountPaths.supportRoot();
    final dbPath = '${dir.path}/marmot.db';

    if (Platform.isAndroid) {
      return Marmot.sqliteWithKey(dbPath: dbPath, dbKey: await _androidDbKey());
    }

    await Marmot.initKeyringStore();
    return Marmot.sqlite(
      dbPath: dbPath,
      serviceId: 'com.zapbook.geeksaxis',
      keyId: 'zapbook_marmot_key_id',
    );
  }

  static const _secure = FlutterSecureStorage();
  static const _keyStorageKey = 'marmot_db_key';

  static Future<Uint8List> _androidDbKey() async {
    final b64 = await _secure.read(key: _keyStorageKey);
    if (b64 != null) return base64Decode(b64);

    final key = Uint8List(32);
    final rng = Random.secure();
    for (var i = 0; i < 32; i++) {
      key[i] = rng.nextInt(256);
    }
    await _secure.write(key: _keyStorageKey, value: base64Encode(key));
    return key;
  }
}
