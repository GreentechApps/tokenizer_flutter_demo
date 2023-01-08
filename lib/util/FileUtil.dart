import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class FileUtil {
  // databasesDir
  static Future<Directory> get dirDatabases async {
    return await getADirInAppSupportDir('databases');
  }

  static Future<String> get announcementDbPath async {
    return join((await dirDatabases).path, 'announcement.db');
  }

  static Future<String> get bookamrksDbPath async {
    return join((await dirDatabases).path, 'bookmarks.db');
  }

  // should be different on different platform
  static Future<Directory> get appSupportDir async {
    if (Platform.isIOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS) {
      return await getApplicationSupportDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  static Future<Directory?> get userVisibleExternalDir async {
    if (Platform.isIOS ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS) {
      return await getApplicationDocumentsDirectory();
    }
  }

  //========================================================
  // get new directory inside appSupportDir
  // for example:
  // appSupportDir: /Users/nix/.../Documents
  // returns: /Users/nix/.../Documents/$dirPath
  //========================================================
  static Future<Directory> getADirInAppSupportDir(String dirName) async {
    var dir = Directory((await appSupportDir).path + Platform.pathSeparator + "$dirName");
    createDirIfNotExists(dir.path);
    return dir;
  }

  // create a directory if not exists already
  static createDirIfNotExists(String dirPath) async {
    if (!(await Directory(dirPath).exists())) {
      try {
        await Directory(dirPath).create(recursive: true);
      } catch (error) {
        print('Error: $error, while creating directory: $dirPath');
      }
    }
  }
}
