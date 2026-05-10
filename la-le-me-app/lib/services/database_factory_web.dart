import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

bool _factoryInitialized = false;

Future<void> initDatabaseFactory() async {
  if (!_factoryInitialized) {
    databaseFactory = databaseFactoryFfiWeb;
    _factoryInitialized = true;
  }
}