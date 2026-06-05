import 'package:injectable/injectable.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:path_provider/path_provider.dart';

@module
abstract class MarmotModule {
  @lazySingleton
  Future<Marmot> marmot() async {
    await Marmot.initKeyringStore();
    final dir = await getApplicationSupportDirectory();
    final dbPath = '${dir.path}/marmot.db';
    return Marmot.sqlite(
      dbPath: dbPath,
      serviceId: 'come.zapbook.geeksaxis',
      keyId: 'marmot-db-key',
    );
  }
}
