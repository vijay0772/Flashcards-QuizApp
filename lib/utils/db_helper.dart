import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const String _databaseName = 'deckwithcard4.db';
  static const int _databaseVersion = 1;

  DBHelper._();
  static final DBHelper _singleton = DBHelper._();
  factory DBHelper() => _singleton;

  Database? _database;

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var dbDir = await getApplicationDocumentsDirectory();
    var dbPath = path.join(dbDir.path, _databaseName);
    var db = await openDatabase(dbPath, version: _databaseVersion, onCreate: _onCreate);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks(
        id INTEGER PRIMARY KEY,
        title TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE flashcards(
        id INTEGER PRIMARY KEY,
        question TEXT,
        answer TEXT,
        deck_id INTEGER,
        FOREIGN KEY (deck_id) REFERENCES decks(id)
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, String? orderBy}) async {
    final db = await this.db;
    return db.query(table, where: where, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await this.db;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(String table, Map<String, dynamic> data) async {
    final db = await this.db;
    await db.update(table, data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> delete(String table, int id) async {
    final db = await this.db;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFlashCardByDeckId(String table, int deckId) async {
    final db = await this.db;
    await db.delete(table, where: 'deck_id = ?', whereArgs: [deckId]);
  }
}
