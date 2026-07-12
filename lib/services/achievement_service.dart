import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_service.dart';
import 'learning_content.dart';
import 'supabase_sync.dart';

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

    // ── First clear: sholat wajib (arc waktu = fase match) ──
    AchievementDef(
      id: 'mid_game',
      title: 'MID GAME',
      desc: 'Pertama kali log sholat Dzuhur',
      tier: AchievementTier.rookie,
      icon: Icons.light_mode,
    ),
    AchievementDef(
      id: 'gold_lane',
      title: 'GOLD LANE',
      desc: 'Pertama kali log sholat Ashar',
      tier: AchievementTier.rookie,
      icon: Icons.flare,
    ),
    AchievementDef(
      id: 'sunset_strike',
      title: 'SUNSET STRIKE',
      desc: 'Pertama kali log sholat Maghrib',
      tier: AchievementTier.rookie,
      icon: Icons.brightness_4,
    ),
    AchievementDef(
      id: 'late_game',
      title: 'LATE GAME',
      desc: 'Pertama kali log sholat Isya',
      tier: AchievementTier.rookie,
      icon: Icons.dark_mode,
    ),

    // ── First clear: sunnah (rawatib = buff sebelum/sesudah battle) ──
    AchievementDef(
      id: 'mana_regen',
      title: 'MANA REGEN',
      desc: 'Pertama kali log Tilawah/Dzikir',
      tier: AchievementTier.rookie,
      icon: Icons.menu_book,
    ),
    AchievementDef(
      id: 'dawn_buff',
      title: 'DAWN BUFF',
      desc: 'Pertama kali Qobliyah Subuh',
      tier: AchievementTier.rookie,
      icon: Icons.shield_moon,
    ),
    AchievementDef(
      id: 'dawn_finisher',
      title: 'DAWN FINISHER',
      desc: 'Pertama kali Ba\'diyah Subuh',
      tier: AchievementTier.rookie,
      icon: Icons.shield,
    ),
    AchievementDef(
      id: 'mid_buff',
      title: 'MID BUFF',
      desc: 'Pertama kali Qobliyah Dzuhur',
      tier: AchievementTier.rookie,
      icon: Icons.add_moderator,
    ),
    AchievementDef(
      id: 'mid_finisher',
      title: 'MID FINISHER',
      desc: 'Pertama kali Ba\'diyah Dzuhur',
      tier: AchievementTier.rookie,
      icon: Icons.security,
    ),
    AchievementDef(
      id: 'gold_buff',
      title: 'GOLD BUFF',
      desc: 'Pertama kali Qobliyah Ashar',
      tier: AchievementTier.rookie,
      icon: Icons.verified_user,
    ),
    AchievementDef(
      id: 'dusk_finisher',
      title: 'DUSK FINISHER',
      desc: 'Pertama kali Ba\'diyah Maghrib',
      tier: AchievementTier.rookie,
      icon: Icons.nightlight,
    ),
    AchievementDef(
      id: 'night_finisher',
      title: 'NIGHT FINISHER',
      desc: 'Pertama kali Ba\'diyah Isya',
      tier: AchievementTier.rookie,
      icon: Icons.bedtime,
    ),

    // ── Rank up ala ranked ML (dari level) ──
    AchievementDef(
      id: 'rank_warrior',
      title: 'WARRIOR',
      desc: 'Capai Level 10',
      tier: AchievementTier.rookie,
      icon: Icons.military_tech,
    ),
    AchievementDef(
      id: 'rank_elite',
      title: 'ELITE',
      desc: 'Capai Level 25',
      tier: AchievementTier.elite,
      icon: Icons.workspace_premium,
    ),
    AchievementDef(
      id: 'rank_master',
      title: 'MASTER',
      desc: 'Capai Level 40',
      tier: AchievementTier.gold,
      icon: Icons.stars,
    ),
    AchievementDef(
      id: 'rank_epic',
      title: 'EPIC',
      desc: 'Capai Level 60',
      tier: AchievementTier.epic,
      icon: Icons.diamond,
    ),
    AchievementDef(
      id: 'rank_mythic',
      title: 'MYTHIC',
      desc: 'Capai Level 80 — Muslim Mythic!',
      tier: AchievementTier.legendary,
      icon: Icons.emoji_events,
    ),

    // ── Solo lane: streak per-ibadah ──
    AchievementDef(
      id: 'subuh_solo_carry',
      title: 'SUBUH SOLO CARRY',
      desc: 'Streak Subuh 7 hari beruntun — lane tersulit',
      tier: AchievementTier.gold,
      glyphText: '7',
    ),
    AchievementDef(
      id: 'jungler',
      title: 'JUNGLER',
      desc: 'Streak Tilawah 7 hari beruntun',
      tier: AchievementTier.gold,
      glyphText: '7',
    ),

    // ── Presisi waktu ──
    AchievementDef(
      id: 'critical_hit',
      title: 'CRITICAL HIT!',
      desc: 'Sholat wajib ≤5 menit setelah adzan',
      tier: AchievementTier.rookie,
      icon: Icons.bolt,
    ),
    AchievementDef(
      id: 'first_strike',
      title: 'FIRST STRIKE',
      desc: 'Sholat Subuh ≤15 menit setelah adzan',
      tier: AchievementTier.elite,
      icon: Icons.gps_fixed,
    ),
    AchievementDef(
      id: 'sharpshooter',
      title: 'SHARPSHOOTER',
      desc: '10× sholat tepat waktu (≤10 menit)',
      tier: AchievementTier.gold,
      icon: Icons.track_changes,
    ),

    // ── Comeback ──
    AchievementDef(
      id: 'comeback_real',
      title: 'COMEBACK IS REAL',
      desc: 'Bangkit lagi setelah streak putus',
      tier: AchievementTier.elite,
      icon: Icons.replay,
    ),
    AchievementDef(
      id: 'phoenix',
      title: 'PHOENIX',
      desc: 'Bangkit 3× setelah streak putus — gak pernah nyerah',
      tier: AchievementTier.epic,
      icon: Icons.local_fire_department,
    ),

    // ── Skill tree: tab Belajar ──
    AchievementDef(
      id: 'first_clear_module',
      title: 'FIRST CLEAR',
      desc: 'Selesaikan modul Belajar pertamamu',
      tier: AchievementTier.rookie,
      icon: Icons.school,
    ),
    AchievementDef(
      id: 'quiz_mvp',
      title: 'MVP',
      desc: 'Skor sempurna 100% di satu quiz',
      tier: AchievementTier.gold,
      icon: Icons.star,
    ),
    AchievementDef(
      id: 'sage',
      title: 'SAGE',
      desc: 'Tamatkan semua 16 modul Belajar',
      tier: AchievementTier.epic,
      icon: Icons.psychology,
    ),

    // ── Combo & koleksi ──
    AchievementDef(
      id: 'wombo_combo',
      title: 'WOMBO COMBO',
      desc: 'Tuntaskan Daily Zikir 100 pertama kali',
      tier: AchievementTier.elite,
      icon: Icons.touch_app,
    ),
    AchievementDef(
      id: 'full_combo',
      title: 'FULL COMBO',
      desc: 'Dalam 1 hari: 5 wajib + Tilawah + Dhuha',
      tier: AchievementTier.epic,
      icon: Icons.whatshot,
    ),
    AchievementDef(
      id: 'collector',
      title: 'COLLECTOR',
      desc: 'Log semua 9 jenis sholat sunnah minimal 1×',
      tier: AchievementTier.epic,
      icon: Icons.collections_bookmark,
    ),
    AchievementDef(
      id: 'hall_of_fame',
      title: 'HALL OF FAME',
      desc: 'Buka semua achievement lainnya 👑',
      tier: AchievementTier.legendary,
      icon: Icons.castle,
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
    SupabaseSync.saveAchievements({
      'unlocked': _unlocked,
      'ts': DateTime.now().toUtc().toIso8601String(),
    }); // fire-and-forget
  }

  static bool isUnlocked(String id) => _unlocked.containsKey(id);

  /// Tanggal unlock (yyyy-MM-dd), null kalau belum terbuka.
  static String? unlockedDate(String id) => _unlocked[id];

  static int get unlockedCount => _unlocked.length;

  static bool _condition(String id, GameState s) {
    // Pakai best — medali streak permanen walau streak sekarang putus.
    final hero = max(s.heroStreak.current, s.heroStreak.best);
    final logs = s.prayerLog;
    bool logged(String p) => logs.any((l) => l.prayer == p);
    bool loggedWajib(String p) =>
        logs.any((l) => l.prayer == p && l.type == 'wajib');
    String adzanFor(String p) => switch (p) {
          'subuh' => s.timings.subuh,
          'dzuhur' => s.timings.dzuhur,
          'ashar' => s.timings.ashar,
          'maghrib' => s.timings.maghrib,
          'isya' => s.timings.isya,
          _ => '',
        };
    // Catatan: log lama dibandingkan dengan jadwal hari ini (aproksimasi
    // yang sama dengan badge early_bird — pergeseran adzan cuma ±menit).
    int timelyCount(int maxMin) => logs.where((l) {
          if (l.type != 'wajib') return false;
          final adzan = adzanFor(l.prayer);
          return adzan.isNotEmpty &&
              GameService.minDiff(l.time, adzan) <= maxMin;
        }).length;
    int bestStreak(StreakState? st) =>
        st == null ? 0 : max(st.current, st.best);
    final learning = LearningService.current.progress;

    return switch (id) {
      'first_blood' => hero >= 1,
      'early_game' => loggedWajib('subuh'),
      'dhuha_secured' => logged('dhuha'),
      'tahajjud_secured' => logged('tahajjud'),
      'double_kill' => hero >= 2,
      'triple_kill' => hero >= 3,
      'unstoppable' => hero >= 5,
      'dominating' => hero >= 7,
      'maniac' => hero >= 14,
      'godlike' => hero >= 30,
      'savage' => hero >= 60,
      'legendary' => hero >= 100,
      // First clear wajib
      'mid_game' => loggedWajib('dzuhur'),
      'gold_lane' => loggedWajib('ashar'),
      'sunset_strike' => loggedWajib('maghrib'),
      'late_game' => loggedWajib('isya'),
      // First clear sunnah
      'mana_regen' => logged('tilawah'),
      'dawn_buff' => logged('rawatib_subuh_qobliyah'),
      'dawn_finisher' => logged('rawatib_subuh_ba_diyyah'),
      'mid_buff' => logged('rawatib_dzuhur_qobliyah'),
      'mid_finisher' => logged('rawatib_dzuhur_ba_diyyah'),
      'gold_buff' => logged('rawatib_ashar_qobliyah'),
      'dusk_finisher' => logged('rawatib_maghrib_ba_diyyah'),
      'night_finisher' => logged('rawatib_isya_ba_diyyah'),
      // Rank up
      'rank_warrior' => s.level >= 10,
      'rank_elite' => s.level >= 25,
      'rank_master' => s.level >= 40,
      'rank_epic' => s.level >= 60,
      'rank_mythic' => s.level >= 80,
      // Solo lane
      'subuh_solo_carry' => bestStreak(s.perPrayerStreaks['subuh']) >= 7,
      'jungler' => bestStreak(s.tilawahStreak) >= 7,
      // Presisi waktu
      'critical_hit' => timelyCount(5) >= 1,
      'first_strike' => logs.any((l) =>
          l.prayer == 'subuh' &&
          l.type == 'wajib' &&
          s.timings.subuh.isNotEmpty &&
          GameService.minDiff(l.time, s.timings.subuh) <= 15),
      'sharpshooter' => timelyCount(10) >= 10,
      // Comeback
      'comeback_real' => s.comebackCount >= 1,
      'phoenix' => s.comebackCount >= 3,
      // Skill tree (Belajar)
      'first_clear_module' => learning.any((p) => p.completed),
      'quiz_mvp' => learning.any((p) => p.quizScore >= 100),
      'sage' => learning.where((p) => p.completed).length >= 16,
      // Combo & koleksi
      'wombo_combo' => s.zikirCounter.count >= GameService.zikirGoal,
      'full_combo' => _hasFullComboDay(logs),
      'collector' => const [
        'dhuha', 'tahajjud',
        'rawatib_subuh_qobliyah', 'rawatib_subuh_ba_diyyah',
        'rawatib_dzuhur_qobliyah', 'rawatib_dzuhur_ba_diyyah',
        'rawatib_ashar_qobliyah', 'rawatib_maghrib_ba_diyyah',
        'rawatib_isya_ba_diyyah',
      ].every(logged),
      // Meta-medali: dievaluasi terakhir (urutan defs), jadi unlock baru
      // di pass yang sama sudah masuk _unlocked.
      'hall_of_fame' => defs
          .where((d) => d.id != 'hall_of_fame')
          .every((d) => _unlocked.containsKey(d.id)),
      _ => false,
    };
  }

  /// Ada satu hari di mana 5 wajib + tilawah + dhuha semua ter-log?
  static bool _hasFullComboDay(List<PrayerLog> logs) {
    final byDate = <String, Set<String>>{};
    for (final l in logs) {
      (byDate[l.date] ??= <String>{}).add(l.prayer);
    }
    const wajib = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
    for (final prayers in byDate.values) {
      if (wajib.every(prayers.contains) &&
          prayers.contains('tilawah') &&
          prayers.contains('dhuha')) {
        return true;
      }
    }
    return false;
  }

  /// Evaluasi semua achievement terhadap state sekarang, simpan yang baru
  /// terbuka. Return definisi yang BARU terbuka — untuk popup announcer.
  /// [silent] tetap menyimpan tapi pemanggil bisa memilih tak menampilkan
  /// popup (mis. backfill saat app pertama dibuka setelah update).
  static Future<List<AchievementDef>> refresh() async {
    await load();
    // Kondisi skill-tree (FIRST CLEAR/MVP/SAGE) baca progress tab Belajar.
    await LearningService.load();
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
