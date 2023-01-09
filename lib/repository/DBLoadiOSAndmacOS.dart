import 'dart:ffi';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class DBLoadiOSAndmacOS {
  // open the database
  static Future<Database?> getDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    Database? db;

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

    try {
      db = await databaseFactoryFfi.openDatabase(
        path,
        options: options,
      );
    } catch (e) {
      print(e.toString());
      databaseFactoryFfi.deleteDatabase(path);
    }
    print("VERSION: ${sqlite3.sqlite3.version}");
    return db;
  }

  static DynamicLibrary? _openExtension() {
    print("_openExtension");
    try {
      return DynamicLibrary.open(
          'sqlite3_arabic_tokenizer.framework/sqlite3_arabic_tokenizer');
    } catch (e) {
      print(e);
      return null;
    }
  }
}
