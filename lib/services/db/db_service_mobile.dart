import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DbService {
  final supabase = Supabase.instance.client;

  Future<void> saveUser(Session session) async {
    final user = session.user;

    await supabase.from('users').upsert({
      'id': user.id,
      'name': user.userMetadata?['full_name'] ?? 'NoName',
      'email': user.email ?? '',
      'last_login': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveGuestUser(String guestId) async {
    final db = await _getDb();

    await db.insert('users', {
      'id': guestId,
      'name': 'Guest_$guestId',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Database> _getDb() async {
    final path = p.join(await getDatabasesPath(), 'app.db');

    final db = await openDatabase(path, version: 1);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT,
        created_at TEXT
      )
    ''');

    return db;
  }
}