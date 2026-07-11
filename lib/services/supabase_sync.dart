import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSync {
  static final _client = Supabase.instance.client;
  static String? _deviceId;

  static String get _id => _deviceId ?? 'noop';
  static void init(String id) => _deviceId = id;

  static Future<void> saveGame(Map<String, dynamic> data) =>
      _upsert({'game': data});
  static Future<void> saveLearning(Map<String, dynamic> data) =>
      _upsert({'learning': data});
  static Future<void> saveAchievements(Map<String, dynamic> data) =>
      _upsert({'achievements': data});

  static Future<Map<String, dynamic>?> load() async {
    try {
      final res = await _client
          .from('user_data')
          .select()
          .eq('device_id', _id)
          .maybeSingle();
      return res as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  static Future<void> _upsert(Map<String, dynamic> extra) async {
    try {
      await _client.from('user_data').upsert({
        'device_id': _id, ...extra,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }
}