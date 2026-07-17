import 'package:supabase_flutter/supabase_flutter.dart';

/// Ponytail: thin wrapper over supabase auth.
class AuthService {
  static SupabaseClient? get _client {
    try { return Supabase.instance.client; } catch (_) { return null; }
  }
  static String? get userId => _client?.auth.currentUser?.id;
  static bool get signedIn => userId != null;

  /// Returns null on success, error message on failure.
  static Future<String?> signUp(String email, String password) async {
    final c = _client;
    if (c == null) return 'Tidak terhubung ke server. Coba lagi nanti.';
    try {
      await c.auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  static Future<String?> signIn(String email, String password) async {
    final c = _client;
    if (c == null) return 'Tidak terhubung ke server. Coba lagi nanti.';
    try {
      await c.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  static Future<void> signOut() async {
    final c = _client;
    if (c == null) return;
    try { await c.auth.signOut(); } catch (_) {}
  }
}
