import 'dart:ffi';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class DBLoadLinux {
  static Future<Database> getDatabase(
    String path, {
    int? version,
    bool readOnly = false,
  }) async {
    sqfliteFfiInit();

    final library = _openExtension();
    if (library != null) {
      final ext = sqlite3.SqliteExtension.inLibrary(
          library, 'sqlite3_sqlitearabictokenizer_init');
      print(
          "SYMBOL ${library.providesSymbol('sqlite3_sqlitearabictokenizer_init')}");
      print("EXTENSION ${ext.toString()}");
      try {
        sqlite3.sqlite3.ensureExtensionLoaded(ext);
      } catch (e) {
        print(e.toString());
      }
      print("SQLITE EXTENSION ${library.toString()} ${library.handle}");
    }

    var databaseFactory = databaseFactoryFfi;
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: version, readOnly: readOnly),
    );
  }

  static DynamicLibrary? _openExtension() {
    print("_openExtension");
    final lib = DynamicLibrary.executable();
    if (lib.providesSymbol("sqlite3_sqlitearabictokenizer_init")) {
      return lib;
    }
    return null;
  }
}
