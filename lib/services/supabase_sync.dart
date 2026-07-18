import 'package:supabase_flutter/supabase_flutter.dart';

/// Sync 3 JSON blobs to Supabase. One table, one row per device.
/// Silent on network errors — local persistence always works.
class SupabaseSync {
  static String? _deviceId;

  static String get _id => _deviceId ?? 'noop';
  static void init(String id) => _deviceId = id;

  // ponytail: lazy — Supabase.initialize() bisa gagal di offline-first launch
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGame(Map<String, dynamic> data) =>
      _upsert({'game': data});
  static Future<void> saveLearning(Map<String, dynamic> data) =>
      _upsert({'learning': data});
  static Future<void> saveAchievements(Map<String, dynamic> data) =>
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

  static Future<void> _upsert(Map<String, dynamic> extra) async {
    final c = _client;
    if (c == null) return;
    try {
      await c.from('user_data').upsert({
        'device_id': _id,
        ...extra,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // silent: local is source of truth
    }
  }
}
