import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class DBLoadAndroid {
  // open the database
  static Future<Database?> getDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    Database? db;

    final library = _openExtension();
    final extension = sqlite3.SqliteExtension.inLibrary(
        library, 'sqlite3_sqlitearabictokenizer_init');
    print(
        "SYMBOL ${library.providesSymbol('sqlite3_sqlitearabictokenizer_init')}");
    print("EXTENSION ${extension.toString()}");
    try {
      sqlite3.sqlite3.ensureExtensionLoaded(extension);
    } catch (e) {
      print("Error ${e.toString()}");
    }
    print("SQLITE EXTENSION ${library.toString()} ${library.handle}");

    try {
      db = await databaseFactoryFfi.openDatabase(
        path,
        options: options,
      );
    } catch (e) {
      print(e.toString());
      databaseFactoryFfi.deleteDatabase(path);
    }
    print("ANDROID");
    print("VERSION: ${sqlite3.sqlite3.version}");
    return db;
  }

  static DynamicLibrary _openExtension() {
    print("_openExtension");
    try {
      return DynamicLibrary.open('libarabictokenizer.so');
      // ignore: avoid_catching_errors
    } on ArgumentError {
      print("ERROR in default");
      // On some (especially old) Android devices, we somehow can't dlopen
      // libraries shipped with the apk. We need to find the full path of the
      // library (/data/data/<id>/lib/libsqlite3.so) and open that one.
      // For details, see https://github.com/simolus3/moor/issues/420
      final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

      // app id ends with the first \0 character in here.
      final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
      final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

      return DynamicLibrary.open(
          '/data/data/$appId/lib/libsqlite3_arabic_tokenizer.so');
    }
  }
}
