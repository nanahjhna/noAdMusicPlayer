import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<Session?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception("Google ID Token이 null입니다.");
    }

    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    return response.session;
  }

  Session? getCurrentSession() {
    return supabase.auth.currentSession;
  }
}