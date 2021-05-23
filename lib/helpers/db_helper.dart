import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DBHelper {
  static Future<Database> _database() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      path.join(dbPath, 'alarms.db'),
      onCreate: (db, version) => db.execute(
          'CREATE TABLE alarms(id TEXT PRIMARY KEY, hour INTEGER, minute INTEGER, repeatingDays TEXT, isRingingToday INTEGER, mathChallenge INTEGER)'),
      version: 1,
    );
  }

  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper._database();
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper._database();
    return db.query(table);
  }

  static Future<void> delete(String table, String id) async {
    final db = await DBHelper._database();
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
