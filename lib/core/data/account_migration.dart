import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart' as logging;
import 'package:ndk/ndk.dart' show Nip19;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapbook/core/identity/account_paths.dart';

class AccountMigration {
  AccountMigration._();

  static const _flag = 'accounts_migrated_v1';

  static const _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final _log = logging.Logger('AccountMigration');

  static Future<void> run(SharedPreferences prefs) async {
    if (prefs.getBool(_flag) ?? false) return;
    try {
      await _migrate(prefs);
    } on Object catch (error, stack) {
      _log.warning('Account migration failed', error, stack);
    } finally {
      await prefs.setBool(_flag, true);
    }
  }

  static Future<void> _migrate(SharedPreferences prefs) async {
    final npub = await _secure.read(key: 'identity_npub');
    final nsec = await _secure.read(key: 'identity_nsec');
    if (npub == null || nsec == null || npub.isEmpty || nsec.isEmpty) return;

    final hex = Nip19.decode(npub);
    if (hex.isEmpty) return;

    await _secure.write(key: 'accounts', value: jsonEncode({npub: nsec}));
    await _secure.write(key: 'active_npub', value: npub);

    final support = await getApplicationSupportDirectory();
    final cache = await getApplicationCacheDirectory();
    final supportDst = '${support.path}/${AccountPaths.accountsDir}/$hex';
    final cacheDst = '${cache.path}/${AccountPaths.accountsDir}/$hex';
    Directory(supportDst).createSync(recursive: true);
    Directory(cacheDst).createSync(recursive: true);

    for (final name in const [
      'marmot.db',
      'nostr_cache.db',
      'book_search.db',
      'book_vectors.db',
    ]) {
      _moveDbFamily(support.path, supportDst, name);
    }
    _moveDir('${support.path}/library', '$supportDst/library');
    _moveDir('${cache.path}/library', '$cacheDst/library');
    _moveDir('${support.path}/densities', '$supportDst/densities');

    await _movePrefList(prefs, 'contacts.npubs', '$hex:contacts.npubs');
    await _movePrefString(prefs, 'nwc_wallet_name', '$hex:nwc_wallet_name');
    await _movePrefBool(
      prefs,
      'circle_prompt_shown',
      '$hex:circle_prompt_shown',
    );

    await _moveSecure('nwc_connection_string', '$hex:nwc_connection_string');
    await _moveSecure('key_package_d_tag', '$hex:key_package_d_tag');
    await _moveSecure('key_package_rotated_at', '$hex:key_package_rotated_at');

    _log.info('Migrated legacy data into accounts/$hex');
  }

  static void _moveDbFamily(String srcDir, String dstDir, String name) {
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      _moveFile('$srcDir/$name$suffix', '$dstDir/$name$suffix');
    }
  }

  static void _moveFile(String src, String dst) {
    final file = File(src);
    if (!file.existsSync()) return;
    try {
      file.renameSync(dst);
    } on FileSystemException {
      file.copySync(dst);
      file.deleteSync();
    }
  }

  static void _moveDir(String src, String dst) {
    final dir = Directory(src);
    if (!dir.existsSync()) return;
    if (Directory(dst).existsSync()) return;
    try {
      dir.renameSync(dst);
    } on FileSystemException {
      _copyDir(dir, Directory(dst));
      dir.deleteSync(recursive: true);
    }
  }

  static void _copyDir(Directory src, Directory dst) {
    dst.createSync(recursive: true);
    for (final entity in src.listSync()) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entity is Directory) {
        _copyDir(entity, Directory('${dst.path}/$name'));
      } else if (entity is File) {
        entity.copySync('${dst.path}/$name');
      }
    }
  }

  static Future<void> _movePrefList(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    final value = prefs.getStringList(from);
    if (value == null) return;
    await prefs.setStringList(to, value);
    await prefs.remove(from);
  }

  static Future<void> _movePrefString(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    final value = prefs.getString(from);
    if (value == null) return;
    await prefs.setString(to, value);
    await prefs.remove(from);
  }

  static Future<void> _movePrefBool(
    SharedPreferences prefs,
    String from,
    String to,
  ) async {
    final value = prefs.getBool(from);
    if (value == null) return;
    await prefs.setBool(to, value);
    await prefs.remove(from);
  }

  static Future<void> _moveSecure(String from, String to) async {
    final value = await _secure.read(key: from);
    if (value == null) return;
    await _secure.write(key: to, value: value);
    await _secure.delete(key: from);
  }
}
