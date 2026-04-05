import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // 🔥 여기가 핵심입니다! 파일 이름을 아예 새롭게 바꿔버리세요.
    final path = p.join(await getDatabasesPath(), 'noAdMusicPlayer_v1.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. 이미지 테이블
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_images (
            id TEXT PRIMARY KEY,
            image_url TEXT,
            thumbnail_url TEXT,
            file_path TEXT,
            created_at INTEGER
          )
        ''');

        // 2. 세트 테이블
        await db.execute('''
          CREATE TABLE IF NOT EXISTS image_sets (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            created_at INTEGER
          )
        ''');

        // 3. 연결 테이블
        await db.execute('''
          CREATE TABLE IF NOT EXISTS image_set_items (
            id TEXT PRIMARY KEY,
            image_set_id TEXT,
            image_id TEXT
          )
        ''');
      },
    );
  }
}