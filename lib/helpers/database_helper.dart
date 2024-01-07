import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {


  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  static late Database _db;




  Future<Database> get db async {
    _db = await initDb();
    return _db;
  }



  DatabaseHelper.internal();

  Future<Database> initDb() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, "ekg.db");
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }



  void _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE user(id INTEGER PRIMARY KEY, name TEXT, surname TEXT,"
        "age INTEGER, gender TEXT, "
        "height INTEGER, weight INTEGER, "
        "smoke BOOLEAN, diabetes BOOLEAN, hypertension BOOLEAN, "
        "ldl INTEGER, hdl INTEGER)");
  }



  Future<int> saveData(Map<String, dynamic> data) async {
    var dbClient = await db;
    int res = await dbClient.insert("user", data);
    return res;
  }



  Future<List<Map<String, dynamic>>> getData() async {
    var dbClient = await db;
    List<Map<String, dynamic>> list = await dbClient.rawQuery("SELECT * FROM user");
    return list;
  }


}