import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../classes/record.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, 'my_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        qrData TEXT,
        comment TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<int> insertRecord(Record record) async {
    final Database db = await instance.database;
    return await db.insert('records', record.toMap());
  }

  Future<List<Record>> getRecords() async {
    final Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('records');
    return List.generate(maps.length, (index) {
      return Record(
        qrData: maps[index]['qrData'],
        comment: maps[index]['comment'],
        timestamp: DateTime.parse(maps[index]['timestamp']),
      );
    });
  }

  Future<int> updateRecord(Record record) async {
    final Database db = await instance.database;
    return await db.update(
      'records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final Database db = await instance.database;
    return await db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
