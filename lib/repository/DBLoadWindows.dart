import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

class DBLoadWindows {
  static _setDlls() {
    String path;

    if (kReleaseMode) {
      var location = Directory.current.path;
      path = normalize(join(location, 'sqlite3.dll'));
    } else {
      var location = Directory.current.path;
      path = normalize(
          join(location, 'windows', 'supportingfiles', 'sqlite3.dll'));
    }

    open.overrideFor(OperatingSystem.windows, () {
      print('loading $path');
      try {
        return DynamicLibrary.open(path);
      } catch (e) {
        stderr.writeln('Failed to load sqlite3.dll at $path ${e}');
        rethrow;
      }
    });

    // Force an open in the main isolate
    // Loading from an isolate seems to break on windows
    sqlite3.sqlite3.openInMemory().dispose();
  }

  // open the database
  static Future<Database?> getDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    _setDlls();

    Database? db;

    final String lpath;
    if (kReleaseMode) {
      var location = Directory.current.path;
      lpath = normalize(join(location, 'sqlite3-arabic-tokenizer.dll'));
    } else {
      var location = Directory.current.path;
      lpath = normalize(join(location, 'windows', 'supportingfiles',
          'sqlite3-arabic-tokenizer.dll'));
    }
    final library = DynamicLibrary.open(lpath);
    sqlite3.sqlite3.ensureExtensionLoaded(sqlite3.SqliteExtension.inLibrary(
        library, 'sqlite3_sqlitearabictokenizer_init'));
    print("LIB ${library.toString()}");

    try {
      db = await databaseFactoryFfi.openDatabase(
        path,
        options: options,
      );
    } catch (e) {
      print(e.toString());
      databaseFactoryFfi.deleteDatabase(path);
    }

    return db;
  }
}
