import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalRepositoryLinux {
  static Future<Database> getDatabase(
    String path, {
    int? version,
    bool readOnly = false,
  }) async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: version, readOnly: readOnly),
    );
  }
}
