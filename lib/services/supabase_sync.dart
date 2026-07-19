import 'package:supabase_flutter/supabase_flutter.dart';

/// Sync 3 JSON blobs to Supabase. One table, one row per user (auth.uid)
/// atau per device (fallback random id kalau belum login).
/// Silent on network errors — local persistence always works.
class SupabaseSync {
  static String? _deviceId;

  static String get _id => _deviceId ?? 'noop';

  /// Init dengan device_id lokal (fallback). Kalau sudah login, AuthService
  /// akan override via [initWithUser].
  static void init(String id) => _deviceId = id;

  /// Override device_id dengan Supabase auth.uid() setelah login berhasil.
  static void initWithUser(String userId) => _deviceId = userId;

  // ponytail: lazy — Supabase.initialize() bisa gagal di offline-first launch
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// True kalau baris berhasil di-upsert (buat feedback UI).
  static Future<bool> saveGame(Map<String, dynamic> data) =>
      _upsert({'game': data});

  static Future<bool> saveLearning(Map<String, dynamic> data) =>
      _upsert({'learning': data});

  static Future<bool> saveAchievements(Map<String, dynamic> data) =>
      _upsert({'achievements': data});

  static Future<Map<String, dynamic>?> load() async {
    final c = _client;
    if (c == null) return null;
    try {
      final res = await c
          .from('user_data')
          .select()
          .eq('device_id', _id)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loadGame() async {
    final row = await load();
    return row?['game'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> loadLearning() async {
    final row = await load();
    return row?['learning'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> loadAchievements() async {
    final row = await load();
    return row?['achievements'] as Map<String, dynamic>?;
  }

  /// Return true kalau upsert sukses, false kalau gagal (network/offline).
  static Future<bool> _upsert(Map<String, dynamic> extra) async {
    final c = _client;
    if (c == null) return false;
    try {
      await c.from('user_data').upsert({
        'device_id': _id,
        ...extra,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (_) {
      // silent: local is source of truth
      return false;
    }
  }
}
