import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tokenizer_flutter_demo/model/Verse.dart';
import 'package:tokenizer_flutter_demo/repository/DBLoadWindows.dart';

import '../util/FileUtil.dart';
import 'DBLoadAndroid.dart';
import 'DBLoadiOSAndmacOS.dart';
import 'LocalRepositoryLinux.dart';

const _databaseName = "quran.db";
const databaseVersion = 7;

const windowsDPassword = 1234;

_writeIsolate(args) {
  var data = args[0];
  Uint8List pdfBytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  File outputFile = args[1];

  outputFile.writeAsBytesSync(pdfBytes, flush: true);
}

class AppDatabase {
  // This is the actual database filename that is saved in the docs directory.

  static final AppDatabase appDatabase = new AppDatabase._internal();

  bool isDBInitiating = false;

  AppDatabase._internal() {}

  factory AppDatabase() {
    return appDatabase;
  }

  // Only allow a single open connection to the database.
  Database? _database;

  Future<Database> get database async {
    if (_database == null && !isDBInitiating) {
      print("[db_update]_isDBInitiating:" + isDBInitiating.toString());
      isDBInitiating = true;
      _database = await initDatabase();
    }

    return _database!;
  }

  static Future<Database> _getDBFromPath(
    String path, {
    int? version,
    bool readOnly = false,
  }) async {
    Database? db;
    try {
      if (Platform.isAndroid) {
        db = await DBLoadAndroid.getDatabase(path,
            options: OpenDatabaseOptions(
              version: version,
              readOnly: readOnly,
              onConfigure: (db) async {},
            ));
      } else if (Platform.isIOS || Platform.isMacOS) {
        db = await DBLoadiOSAndmacOS.getDatabase(path,
            options: OpenDatabaseOptions(
              version: version,
              readOnly: readOnly,
              onConfigure: (db) async {},
            ));
      } else if (Platform.isWindows) {
        db = await DBLoadWindows.getDatabase(path,
            options: OpenDatabaseOptions(
              version: version,
              readOnly: readOnly,
              onConfigure: (db) async {
                await db.rawQuery("PRAGMA KEY='$windowsDPassword'");
              },
            ));
      } else if (Platform.isLinux) {
        db = await LocalRepositoryLinux.getDatabase(
          path,
          version: version,
          readOnly: readOnly,
        );
      } else {
        db = await openDatabase(path, version: version, readOnly: readOnly);
      }
    } catch (e) {
      print('Error opening database: ${e.toString()}');
    }
    return db!;
  }

// open the database
  Future<Database> initDatabase() async {
    final String dirDBPath = (await FileUtil.dirDatabases).path;
    String path = join(dirDBPath, _databaseName);
    print(path);
    final bool exists = await File(path).exists();
    Database db;
    print("Does it exist $exists");

    if (!exists) {
      print("[db_update]Creating new copy from asset");

      // Bookmark migraion is needed for one time while upgrading flutter version over native android.
      // In that case native android db is not eisted as the database directory of native android
      // is different from the flutter one.
      var pref = await SharedPreferences.getInstance();
      pref.setBool('isMigrated', true);

      await copyDataBaseFromAsset(path);
      db = await _getDBFromPath(
        path,
        version: databaseVersion,
      );
    } else {
      db = await _getDBFromPath(path, readOnly: false);
    }

    try {
      // open the database
      var dbVersion = await db.getVersion();
      print("[db_update]Version compare $dbVersion $databaseVersion");

      if (dbVersion < databaseVersion) {
        print("[db_update]Creating new copy from asset as version low");
        await db.close();
        await copyDataBaseFromAsset(path);
        db = await _getDBFromPath(path, version: databaseVersion);
        await _onDBUpdate(dbVersion, databaseVersion);
      } else {
        print("[db_update]Opening existing database");
        // try {
        //   await db.rawQuery("select count(*) from verses");
        // } on DatabaseException {
        //   print("[db_update]Corrupted file, should copy again");
        //   await deleteDatabase(path);
        //   await copyDataBaseFromAsset(path);
        //   db = await _getDBFromPath(path, version: databaseVersion);
        // }
      }
    } catch (e) {
      print(e.toString());
      deleteDatabase(path);
    }

    return db;
  }

  Future<bool> copyDataBaseFromAsset(String path) async {
    // Make sure the parent directory exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}

    // Copy from asset
    ByteData data = await rootBundle.load("assets/quran.db");

    final outputFile = File(path);

    await compute(_writeIsolate, [data, outputFile]);
    print('Copy done!');

    return true;
  }

  _onDBUpdate(int dbVersion, int databaseVersion) {}

  Future<void> testTokenizer() async {
    Database? db = await (database);
    final maps = await db
        .rawQuery("SELECT rowid, * FROM verses where text MATCH ?", ["الحمد"]);
    print("testTokenizer ${maps.length}");
    final verses = maps.map(Verse.fromJson).toList();
    verses.forEach((element) => print(element));
  }

  Future<List<Verse>> search(String key) async {
    Database? db = await (database);
    final maps = await db
        .rawQuery("SELECT rowid, * FROM verses where text MATCH ?", [key]);
    print("search ${key} ${maps.length}");
    final verses = maps.map(Verse.fromJson).toList();
    verses.forEach((element) => print(element));
    return verses;
  }
}
