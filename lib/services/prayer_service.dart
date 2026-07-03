import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ponytail: stdlib HttpClient + SharedPreferences. No dio, no riverpod.
/// API: api.myquran.com/v3 (Kemenag proxy), with Aladhan fallback.
/// v3 changed from numeric city IDs to MD5 city IDs and date-keyed jadwal map.
class PrayerService {
  static const _base = 'https://api.myquran.com/v3/sholat';
  static const _aladhanBase = 'https://api.aladhan.com/v1/timingsByCity';
  static const _cacheKey = 'prayer_cache_v2';
  static final _client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

  static Future<List<Map<String, dynamic>>> searchCities(String q) async {
    if (q.trim().isEmpty) return const [];
    // v3: /kabkota/cari/{keyword} (was /kota/cari/{q} in v2)
    final uri = Uri.parse('$_base/kabkota/cari/${Uri.encodeComponent(q.trim())}');
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

  /// Fetch jadwal for [date] (defaults today). Tries Kemenag first, then Aladhan fallback.
  static Future<Map<String, String>?> fetchSchedule({
    required String cityId,
    DateTime? date,
    String? cityName,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr = _dateKey(d);

    final cached = await _loadCache(cityId, dateStr);
    if (cached != null) return cached;

    final kemenag = await _fetchKemenag(cityId: cityId, date: d);
    if (kemenag != null) {
      await _saveCache(cityId, dateStr, kemenag);
      return kemenag;
    }

    if (cityName != null && cityName.trim().isNotEmpty) {
      final aladhan = await _fetchAladhan(cityName: cityName.trim(), date: d);
      if (aladhan != null) {
        await _saveCache(cityId, dateStr, aladhan);
        return aladhan;
      }
    }

    // ponytail: stale cache is better than nothing
    return _loadAnyCache(cityId);
  }

  static Future<Map<String, String>?> _fetchKemenag({
    required String cityId,
    required DateTime date,
  }) async {
    // v3: /jadwal/{cityId}/{YYYY-MM-DD}  (was /jadwal/{cityId}/{Y}/{M}/{D} in v2)
    // v3 response: data.jadwal["YYYY-MM-DD"] = {tanggal, imsak, subuh, ...}
    final dateKey = _dateKey(date);
    final uri = Uri.parse('$_base/jadwal/$cityId/$dateKey');
    try {
      final req = await _client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['status'] != true) return null;
      final data = (json['data']) as Map<String, dynamic>?;
      if (data == null) return null;
      final jadwalMap = (data['jadwal']) as Map<String, dynamic>?;
      if (jadwalMap == null || jadwalMap.isEmpty) return null;
      // v3: jadwal is date-keyed map, take the entry for this date
      final jadwal = (jadwalMap[dateKey] ?? jadwalMap.values.first)
          as Map<String, dynamic>;
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
        'lokasi': (data['kabko'] as String?) ?? '',
        'daerah': (data['prov'] as String?) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>?> _fetchAladhan({
    required String cityName,
    required DateTime date,
  }) async {
    final clean = cityName
        .replaceAll(RegExp(r'(kota|kab\.|kabupaten)\s*', caseSensitive: false), '')
        .trim();
    if (clean.isEmpty) return null;
    final uri = Uri.parse(
      '$_aladhanBase?city=${Uri.encodeComponent(clean)}&country=${Uri.encodeComponent('Indonesia')}&method=11',
    );
    try {
      final req = await _client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final timings = (json['data']?['timings']) as Map<String, dynamic>?;
      if (timings == null) return null;
      String cleanTime(String t) {
        final parts = t.trim().split(' ');
        final first = parts.isNotEmpty ? parts[0] : t.trim();
        return first.length >= 5 ? first.substring(0, 5) : first;
      }
      return {
        'imsak': '00:00',
        'subuh': cleanTime(timings['Fajr'] as String? ?? ''),
        'terbit': cleanTime(timings['Sunrise'] as String? ?? ''),
        'dhuha': '00:00',
        'dzuhur': cleanTime(timings['Dhuhr'] as String? ?? ''),
        'ashar': cleanTime(timings['Asr'] as String? ?? ''),
        'maghrib': cleanTime(timings['Maghrib'] as String? ?? ''),
        'isya': cleanTime(timings['Isha'] as String? ?? ''),
        'tanggal': _dateKey(date),
        'lokasi': cityName,
        'daerah': '',
      };
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<Map<String, String>?> _loadCache(String cityId, String date) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['cityId'] != cityId || map['date'] != date) return null;
      return (map['timings'] as Map<String, dynamic>).cast<String, String>();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>?> _loadAnyCache(String cityId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['cityId'] != cityId) return null;
      return (map['timings'] as Map<String, dynamic>).cast<String, String>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(String cityId, String date, Map<String, String> timings) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_cacheKey, jsonEncode({
      'cityId': cityId,
      'date': date,
      'timings': timings,
    }));
  }

  // --- SharedPreferences helpers ---
  /// Bump setiap kali lokasi diganti. Tab home & jadwal hidup terus di
  /// IndexedStack (initState sekali), jadi mereka mendengarkan ini untuk
  /// refetch jadwal saat kota diganti dari tab lain.
  static final ValueNotifier<int> locationVersion = ValueNotifier(0);

  static Future<void> saveLocation(String id, String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('city_id', id);
    await p.setString('city_name', name);
    locationVersion.value++;
  }

  static Future<({String id, String name})?> loadLocation() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('city_id');
    final name = p.getString('city_name');
    if (id == null || name == null) return null;
    return (id: id, name: name);
  }
}
