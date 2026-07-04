import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_service.dart';

/// Achievement system ala Mobile Legends — medali kill-streak untuk ibadah.
/// Terpisah dari badge system lama (GameService.badgeDefs): badge = koleksi
/// emoji sederhana, achievement = medali bertingkat dengan popup announcer.
///
/// Streak yang dipakai adalah HERO STREAK (5/5 wajib per hari, sudah dihitung
/// GameService.logPrayer). Medali streak memakai nilai tertinggi yang pernah
/// dicapai (best), jadi sekali terbuka tidak pernah hilang walau streak putus.

enum AchievementTier { rookie, elite, gold, epic, legendary }

class AchievementDef {
  final String id;
  final String title;
  final String desc;
  final AchievementTier tier;

  /// Ikon untuk achievement "momen pertama".
  final IconData? icon;

  /// Angka hari untuk medali streak — tampil besar di tengah medali,
  /// ala kill-count Mobile Legends. Kalau diisi, [icon] diabaikan.
  final String? glyphText;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.desc,
    required this.tier,
    this.icon,
    this.glyphText,
  });
}

class AchievementService {
  static const _prefKey = 'achievements_unlocked'; // JSON {id: 'yyyy-MM-dd'}

  static const defs = <AchievementDef>[
    AchievementDef(
      id: 'first_blood',
      title: 'FIRST BLOOD!',
      desc: 'Selesaikan 5 sholat wajib dalam 1 hari (Hero Streak dimulai!)',
      tier: AchievementTier.rookie,
      icon: Icons.water_drop,
    ),
    AchievementDef(
      id: 'early_game',
      title: 'EARLY GAME',
      desc: 'Sholat Subuh pertamamu tercatat',
      tier: AchievementTier.rookie,
      icon: Icons.wb_twilight,
    ),
    AchievementDef(
      id: 'dhuha_secured',
      title: 'DHUHA SECURED',
      desc: 'Pertama kali log sholat Dhuha',
      tier: AchievementTier.rookie,
      icon: Icons.wb_sunny,
    ),
    AchievementDef(
      id: 'tahajjud_secured',
      title: 'TAHAJJUD SECURED',
      desc: 'Pertama kali log sholat Tahajjud',
      tier: AchievementTier.rookie,
      icon: Icons.nights_stay,
    ),
    AchievementDef(
      id: 'double_kill',
      title: 'DOUBLE KILL',
      desc: 'Hero Streak 2 hari beruntun',
      tier: AchievementTier.elite,
      glyphText: '2',
    ),
    AchievementDef(
      id: 'triple_kill',
      title: 'TRIPLE KILL',
      desc: 'Hero Streak 3 hari beruntun',
      tier: AchievementTier.elite,
      glyphText: '3',
    ),
    AchievementDef(
      id: 'unstoppable',
      title: 'UNSTOPPABLE!',
      desc: 'Hero Streak 5 hari beruntun',
      tier: AchievementTier.gold,
      glyphText: '5',
    ),
    AchievementDef(
      id: 'dominating',
      title: 'DOMINATING!',
      desc: 'Hero Streak 7 hari beruntun',
      tier: AchievementTier.gold,
      glyphText: '7',
    ),
    AchievementDef(
      id: 'maniac',
      title: 'MANIAC!',
      desc: 'Hero Streak 14 hari beruntun',
      tier: AchievementTier.epic,
      glyphText: '14',
    ),
    AchievementDef(
      id: 'godlike',
      title: 'GODLIKE!',
      desc: 'Hero Streak 30 hari beruntun',
      tier: AchievementTier.epic,
      glyphText: '30',
    ),
    AchievementDef(
      id: 'savage',
      title: 'SAVAGE!',
      desc: 'Hero Streak 60 hari beruntun',
      tier: AchievementTier.legendary,
      glyphText: '60',
    ),
    AchievementDef(
      id: 'legendary',
      title: 'LEGENDARY!',
      desc: 'Hero Streak 100 hari beruntun',
      tier: AchievementTier.legendary,
      glyphText: '100',
    ),
  ];

  static Map<String, String> _unlocked = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _unlocked = Map<String, String>.from(jsonDecode(raw) as Map);
      } catch (_) {
        _unlocked = {};
      }
    }
    _loaded = true;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_unlocked));
  }

  static bool isUnlocked(String id) => _unlocked.containsKey(id);

  /// Tanggal unlock (yyyy-MM-dd), null kalau belum terbuka.
  static String? unlockedDate(String id) => _unlocked[id];

  static int get unlockedCount => _unlocked.length;

  static bool _condition(String id, GameState s) {
    // Pakai best — medali streak permanen walau streak sekarang putus.
    final hero = max(s.heroStreak.current, s.heroStreak.best);
    return switch (id) {
      'first_blood' => hero >= 1,
      'early_game' =>
        s.prayerLog.any((l) => l.prayer == 'subuh' && l.type == 'wajib'),
      'dhuha_secured' => s.prayerLog.any((l) => l.prayer == 'dhuha'),
      'tahajjud_secured' => s.prayerLog.any((l) => l.prayer == 'tahajjud'),
      'double_kill' => hero >= 2,
      'triple_kill' => hero >= 3,
      'unstoppable' => hero >= 5,
      'dominating' => hero >= 7,
      'maniac' => hero >= 14,
      'godlike' => hero >= 30,
      'savage' => hero >= 60,
      'legendary' => hero >= 100,
      _ => false,
    };
  }

  /// Evaluasi semua achievement terhadap state sekarang, simpan yang baru
  /// terbuka. Return definisi yang BARU terbuka — untuk popup announcer.
  /// [silent] tetap menyimpan tapi pemanggil bisa memilih tak menampilkan
  /// popup (mis. backfill saat app pertama dibuka setelah update).
  static Future<List<AchievementDef>> refresh() async {
    await load();
    final s = GameService.current;
    final newly = <AchievementDef>[];
    for (final d in defs) {
      if (!_unlocked.containsKey(d.id) && _condition(d.id, s)) {
        _unlocked[d.id] = GameService.todayStr();
        newly.add(d);
      }
    }
    if (newly.isNotEmpty) await _persist();
    return newly;
  }
}
