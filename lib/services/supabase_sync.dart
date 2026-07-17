import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Sync 3 JSON blobs to Supabase. One table, one row per user.
/// Silent on network errors — local is the fallback truth.
class SupabaseSync {
  static String? get _id => AuthService.userId;

  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ── Saves ──
  static Future<void> saveGame(Map<String, dynamic> data) =>
      _upsert({'game': data});
  static Future<void> saveLearning(Map<String, dynamic> data) =>
      _upsert({'learning': data});
  static Future<void> saveAchievements(Map<String, dynamic> data) =>
      _upsert({'achievements': data});

  // ── Loads ──
  static Future<Map<String, dynamic>?> loadGame() async {
    final row = await _fetch();
    if (row == null) return null;
    return row['game'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> loadLearning() async {
    final row = await _fetch();
    if (row == null) return null;
    return row['learning'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> loadAchievements() async {
    final row = await _fetch();
    if (row == null) return null;
    return row['achievements'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>?> _fetch() async {
    final id = _id;
    final c = _client;
    if (id == null || c == null) return null;
    try {
      return await c
          .from('user_data')
          .select()
          .eq('user_id', id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _upsert(Map<String, dynamic> extra) async {
    final id = _id;
    final c = _client;
    if (id == null || c == null) return;
    try {
      // Fetch existing to avoid nulling sibling columns on partial update
      Map<String, dynamic> row = {};
      try {
        final existing = await c
            .from('user_data')
            .select()
            .eq('user_id', id)
            .maybeSingle();
        if (existing != null) row = Map<String, dynamic>.from(existing);
      } catch (_) {}
      await c.from('user_data').upsert({
        'user_id': id,
        ...row,
        ...extra,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // silent: local is source of truth
    }
  }
}
