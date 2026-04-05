import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // 🔥 추가

class AuthService {
  final supabase = Supabase.instance.client;

  Future<Session?> signInWithGoogle() async {
    final redirectUrl = kReleaseMode
        ? 'https://noAdMusicPlayer.netlify.app' // 🔥 배포용
        : 'http://localhost:5173';      // 🔥 로컬용

    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );

    return null;
  }

  Session? getCurrentSession() {
    return supabase.auth.currentSession;
  }
}