import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth layer: Google Sign-In → Supabase Auth.
/// Device-scoped progress (SharedPreferences) tetap jadi source of truth lokal,
/// tapi setelah login, SupabaseSync pakai auth.uid() sebagai device_id agar
/// progress bisa di-restore lintas device / lintas install.
///
/// Fallback: kalau login gagal / user logout, pakai device_id lokal (random)
/// supaya app tetap jalan offline-first.
class AuthService {
  static const _prefGoogleUser = 'google_user_email';

  /// Pakai Android client_id (bukan Web) ⸺ yg ini di-approve oleh Google Sign In SDK
  /// untuk OAuth dari perangkat Android.
  static final _google = GoogleSignIn(
    clientId: '691907686915-hhb5r3vhirhtcp4a6ihev4vt83ctgkko.apps.googleusercontent.com',
    scopes: ['email'],
  );

  static String? _userId;
  static String? get userId => _userId;
  static bool get isSignedIn => _userId != null;

  /// Inisialisasi: coba restore session Supabase (refresh token) dulu.
  /// Return true kalau ada session aktif.
  static Future<bool> init() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _userId = session.user.id;
        return true;
      }
    } catch (_) {
      // session mungkin expired — biarkan signInWithIdToken di handle
    }
    return false;
  }

  /// Login dengan Google. Return userId (Supabase auth.uid) atau null kalau gagal/batal.
  static Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null; // user batal

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return null;

      // Supabase akan create user otomatis kalau belum ada.
      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final uid = res.user?.id;
      if (uid == null) return null;

      _userId = uid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefGoogleUser, googleUser.email);
      return uid;
    } catch (e) {
      debugPrint('[AuthService] Google sign-in gagal: $e');
      return null;
    }
  }

  /// Logout: clear Supabase session + Google sign-out. Progress lokal tetap utuh.
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
