import 'package:supabase_flutter/supabase_flutter.dart';

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
    // 웹은 SQLite 없음 → 필요하면 Supabase에 저장
    await supabase.from('users').upsert({
      'id': guestId,
      'name': 'Guest_$guestId',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}