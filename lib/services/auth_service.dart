import 'package:supabase_flutter/supabase_flutter.dart';

/// Ponytail: thin wrapper over supabase auth. Session persists on disk
/// across app restarts. On reinstall user must sign in again — that's the fix.
class AuthService {
  static String? get userId => Supabase.instance.client.auth.currentUser?.id;
  static bool get signedIn => userId != null;

  /// Returns null on success, error message on failure.
  static Future<String?> signUp(String email, String password) async {
    final res = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    return res.error?.message;
  }

  static Future<String?> signIn(String email, String password) async {
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.error?.message;
  }

  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
