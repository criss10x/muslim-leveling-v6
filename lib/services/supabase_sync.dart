import 'package:supabase_flutter/supabase_flutter.dart';

/// Sync 3 JSON blobs to Supabase. One table, one row per **signed-in** user.
///
/// RLS: `auth.uid()::text = device_id` — guest random ids can never pass, so
/// we simply refuse to hit the network until [initWithUser] after Google login.
/// Local SharedPreferences remains source of truth offline.
class SupabaseSync {
  static String? _userId;

  /// True only after Google → Supabase Auth succeeds.
  static bool get canSync => _userId != null && _userId!.isNotEmpty;

  static String get _id {
    final id = _userId;
    if (id == null || id.isEmpty) {
      throw StateError('SupabaseSync used while signed out');
    }
    return id;
  }

  /// Kept for call-site compatibility (main still creates a local device_id).
  /// Guest ids must NOT drive cloud rows — RLS would reject them anyway.
  // ponytail: no-op; cloud only after initWithUser
  static void init(String id) {}

  /// Set row key = auth.uid() after login.
  static void initWithUser(String userId) => _userId = userId;

  /// Drop cloud identity on logout (local prefs stay).
  static void clearUser() => _userId = null;

  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveGame(Map<String, dynamic> data) =>
      _upsert({'game': data});

  static Future<bool> saveLearning(Map<String, dynamic> data) =>
      _upsert({'learning': data});

  static Future<bool> saveAchievements(Map<String, dynamic> data) =>
      _upsert({'achievements': data});

  static Future<Map<String, dynamic>?> load() async {
    if (!canSync) return null;
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

  static Future<bool> _upsert(Map<String, dynamic> extra) async {
    if (!canSync) return false;
    final c = _client;
    if (c == null) return false;
    try {
      await c.from('user_data').upsert(
        {
          'device_id': _id,
          ...extra,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'device_id',
      );
      return true;
    } catch (_) {
      // silent: local is source of truth
      return false;
    }
  }
}
