import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth layer: Google Sign-In → Supabase Auth.
/// Device-scoped progress (SharedPreferences) tetap jadi source of truth lokal,
/// tapi setelah login, SupabaseSync pakai auth.uid() sebagai device_id agar
/// progress bisa di-restore lintas device / lintas install.
///
/// ⚠️ PRASYARAT:
/// 1. SHA-1 fingerprint debug & release keystore harus terdaftar di Firebase Console.
///    - Debug default: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
///    - Release: punyamu sendiri
/// 2. google-services.json harus punya Web OAuth client (client_type: 3) biar idToken
///    bisa di-generate. Cek: cat android/app/google-services.json | grep client_type
///    Kalau cuma type 1 (Android), idToken bakal null.
///
/// Fallback: kalau login gagal / user logout, pakai device_id lokal (random)
/// supaya app tetap jalan offline-first.
class AuthService {
  static const _prefGoogleUser = 'google_user_email';
  static String? _lastError;

  /// Getter biar UI bisa tampilkan error terakhir.
  static String? get lastError => _lastError;

  /// Web client ID dari Firebase Console — WAJIB untuk idToken.
  /// Ini client_id dari Web OAuth (client_type: 3) di google-services.json.
  /// Kalau belum ada, login Google bakal gagal.
  static const _webClientId = '691907686915-2kkvt45674moh5b79uu9udj3s4k6to0s.apps.googleusercontent.com';

  /// Android client ID — dipakai google_sign_in buat native auth.
  static final _google = GoogleSignIn(
    clientId: _webClientId,
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
      if (googleUser == null) {
        _lastError = 'Pengguna membatalkan login.';
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _lastError = 'Google tidak mengembalikan idToken. '
            'Penyebab: (1) Web OAuth client (client_type: 3) belum ditambahkan di '
            'Firebase Console, atau (2) SHA-1 fingerprint belum terdaftar. '
            'Cek Firebase Console → Project Settings → General → Your apps → Android.';
        return null;
      }

      // Supabase akan create user otomatis kalau belum ada.
      final res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final uid = res.session?.user.id;
      if (uid == null) {
        _lastError = 'Supabase Auth gagal — session kosong.';
        return null;
      }

      _userId = uid;
      _lastError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefGoogleUser, googleUser.email);
      return uid;
    } catch (e) {
      if (e is Exception) {
        _lastError = 'Error: $e';
      } else {
        _lastError = 'Error non-Exception: $e';
      }
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
