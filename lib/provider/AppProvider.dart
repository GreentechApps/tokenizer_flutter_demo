import 'package:flutter/material.dart';
import 'package:tokenizer_flutter_demo/repository/AppDatabase.dart';

class AppProvider extends ChangeNotifier {
  final _appDatabase = AppDatabase();

  AppProvider() {
    _appDatabase.testTokenizer();
  }
}
