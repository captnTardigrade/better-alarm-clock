import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

import '../data/alarms_provider.dart';

class DBHelper {
  static Future<Database> _database() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      path.join(dbPath, 'alarms.db'),
      onCreate: (db, version) => db.execute(
          'CREATE TABLE alarms(id INTEGER PRIMARY KEY, hour INTEGER, minute INTEGER, repeatingDays TEXT, numPuzzles INTEGER, mathChallenge INTEGER, isEnabled INTEGER)'),
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

  static Future<void> delete(String table, int id) async {
    final db = await DBHelper._database();
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> update(String table, Alarm newAlarm) async {
    final db = await DBHelper._database();
    await db.update(
      table,
      newAlarm.data,
      where: 'id = ?',
      whereArgs: [newAlarm.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
