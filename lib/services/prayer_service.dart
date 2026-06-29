import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// ponytail: stdlib HttpClient + SharedPreferences. No dio, no riverpod.
/// API: api.myquran.com/v2 — proxy publik untuk data Kemenag.
class PrayerService {
  static const _base = 'https://api.myquran.com/v2/sholat';
  static final _client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

  static Future<List<Map<String, dynamic>>> searchCities(String q) async {
    if (q.trim().isEmpty) return const [];
    final uri = Uri.parse('$_base/kota/cari/${Uri.encodeComponent(q.trim())}');
    try {
      final req = await _client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) return const [];
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['status'] != true) return const [];
      final data = json['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map) return [data.cast<String, dynamic>()];
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Fetch jadwal for today (or given date). Returns null on failure.
  static Future<Map<String, String>?> fetchSchedule({
    required String cityId,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final uri = Uri.parse(
      '$_base/jadwal/$cityId/${d.year}/${d.month}/${d.day}',
    );
    try {
      final req = await _client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['status'] != true) return null;
      final jadwal = (json['data']?['jadwal']) as Map<String, dynamic>?;
      if (jadwal == null) return null;
      return {
        'imsak': jadwal['imsak'] as String? ?? '',
        'subuh': jadwal['subuh'] as String? ?? '',
        'terbit': jadwal['terbit'] as String? ?? '',
        'dhuha': jadwal['dhuha'] as String? ?? '',
        'dzuhur': jadwal['dzuhur'] as String? ?? '',
        'ashar': jadwal['ashar'] as String? ?? '',
        'maghrib': jadwal['maghrib'] as String? ?? '',
        'isya': jadwal['isya'] as String? ?? '',
        'tanggal': jadwal['tanggal'] as String? ?? '',
        'lokasi': (json['data']?['lokasi'] as String?) ?? '',
        'daerah': (json['data']?['daerah'] as String?) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // --- SharedPreferences helpers ---
  static Future<void> saveLocation(String id, String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('city_id', id);
    await p.setString('city_name', name);
  }

  static Future<({String id, String name})?> loadLocation() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('city_id');
    final name = p.getString('city_name');
    if (id == null || name == null) return null;
    return (id: id, name: name);
  }
}
