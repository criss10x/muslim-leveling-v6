import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth layer: Google Sign-In → Supabase Auth.
/// Device-scoped progress (SharedPreferences) tetap source of truth lokal.
/// Setelah login, SupabaseSync pakai auth.uid() agar progress lintas device.
///
/// Android: JANGAN isi [GoogleSignIn.clientId] dengan Web OAuth.
/// Pakai [GoogleSignIn.serverClientId] = Web client (client_type: 3) biar idToken
/// keluar. Android client di-resolve dari google-services.json + SHA-1.
class AuthService {
  static const _prefGoogleUser = 'google_user_email';
  static String? _lastError;

  static String? get lastError => _lastError;

  /// Web OAuth client (client_type: 3) — wajib untuk idToken → Supabase.
  static const _webClientId =
      '691907686915-2kkvt45674moh5b79uu9udj3s4k6to0s.apps.googleusercontent.com';

  static final _google = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: const ['email', 'profile'],
  );

  static String? _userId;
  static String? get userId => _userId;
  static bool get isSignedIn => _userId != null;

  static Future<bool> init() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _userId = session.user.id;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Return Supabase auth.uid, atau null kalau batal/gagal.
  static Future<String?> signInWithGoogle() async {
    _lastError = null;
    try {
      // Bersihkan sesi Google lama biar picker gak stuck di account mati.
      try {
        await _google.signOut();
      } catch (_) {}

      final googleUser = await _google.signIn();
      if (googleUser == null) {
        _lastError = 'Pengguna membatalkan login.';
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _lastError =
            'Google tidak mengembalikan idToken. Cek: (1) serverClientId = Web OAuth, '
            '(2) SHA-1 debug/release terdaftar di Firebase, '
            '(3) Google provider aktif di Supabase Auth.';
        return null;
      }

      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final uid = res.session?.user.id ?? res.user?.id;
      if (uid == null) {
        _lastError = 'Supabase Auth gagal — session kosong.';
        return null;
      }

      _userId = uid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefGoogleUser, googleUser.email);
      return uid;
    } catch (e) {
      _lastError = 'Error: $e';
      debugPrint('[AuthService] Google sign-in gagal: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _google.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefGoogleUser);
  }

  static Future<String?> get savedEmail async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefGoogleUser);
  }
}
