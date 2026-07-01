import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ponytail: single-file game state. No riverpod, no bloc.
// Port dari V3 GameViewModel logic. State persisted as JSON di SharedPreferences.

// ─── Data models (mirror V3 DataModels.kt) ───

class Timings {
  final String imsak, subuh, terbit, dhuha, dzuhur, ashar, maghrib, isya;
  Timings({
    this.imsak = '04:30',
    this.subuh = '04:42',
    this.terbit = '05:55',
    this.dhuha = '06:20',
    this.dzuhur = '12:01',
    this.ashar = '15:20',
    this.maghrib = '17:55',
    this.isya = '19:08',
  });
  factory Timings.fromMap(Map<String, dynamic> m) => Timings(
        imsak: m['imsak'] ?? '04:30',
        subuh: m['subuh'] ?? '04:42',
        terbit: m['terbit'] ?? '05:55',
        dhuha: m['dhuha'] ?? '06:20',
        dzuhur: m['dzuhur'] ?? '12:01',
        ashar: m['ashar'] ?? '15:20',
        maghrib: m['maghrib'] ?? '17:55',
        isya: m['isya'] ?? '19:08',
      );
  Map<String, dynamic> toMap() => {
        'imsak': imsak, 'subuh': subuh, 'terbit': terbit, 'dhuha': dhuha,
        'dzuhur': dzuhur, 'ashar': ashar, 'maghrib': maghrib, 'isya': isya,
      };
}

class PrayerLog {
  final String date, prayer, time, type;
  PrayerLog({required this.date, required this.prayer, required this.time, required this.type});
  factory PrayerLog.fromMap(Map<String, dynamic> m) => PrayerLog(
        date: m['date'], prayer: m['prayer'], time: m['time'], type: m['type']);
  Map<String, dynamic> toMap() => {'date': date, 'prayer': prayer, 'time': time, 'type': type};
}

class StreakState {
  final int current, best;
  final String lastDate;
  final bool freezeAvailable;
  StreakState({this.current = 0, this.best = 0, this.lastDate = '', this.freezeAvailable = true});
  StreakState copyWith({int? current, int? best, String? lastDate, bool? freezeAvailable}) => StreakState(
        current: current ?? this.current,
        best: best ?? this.best,
        lastDate: lastDate ?? this.lastDate,
        freezeAvailable: freezeAvailable ?? this.freezeAvailable,
      );
  factory StreakState.fromMap(Map<String, dynamic> m) => StreakState(
        current: m['current'] ?? 0, best: m['best'] ?? 0,
        lastDate: m['lastDate'] ?? '',
        freezeAvailable: m['freezeAvailable'] ?? true);
  Map<String, dynamic> toMap() => {
    'current': current, 'best': best, 'lastDate': lastDate,
    'freezeAvailable': freezeAvailable};
}

class Quest {
  final String id, desc;
  final int xpReward, target, progress;
  final bool completed, claimed;
  Quest({
    required this.id, required this.desc, required this.xpReward,
    required this.target, required this.progress, required this.completed, required this.claimed,
  });
  Quest copyWith({int? progress, bool? completed, bool? claimed}) => Quest(
        id: id, desc: desc, xpReward: xpReward, target: target,
        progress: progress ?? this.progress, completed: completed ?? this.completed,
        claimed: claimed ?? this.claimed);
  factory Quest.fromMap(Map<String, dynamic> m) => Quest(
        id: m['id'], desc: m['desc'], xpReward: m['xpReward'], target: m['target'],
        progress: m['progress'] ?? 0, completed: m['completed'] ?? false, claimed: m['claimed'] ?? false);
  Map<String, dynamic> toMap() => {
        'id': id, 'desc': desc, 'xpReward': xpReward, 'target': target,
        'progress': progress, 'completed': completed, 'claimed': claimed};
}

class LevelInfo {
  final int level, xpInCurrentLevel, xpNeededForNextLevel;
  final double progress;
  LevelInfo({required this.level, required this.xpInCurrentLevel,
      required this.xpNeededForNextLevel, required this.progress});
}

class GameState {
  final int xp, level;
  final Timings timings;
  final List<PrayerLog> prayerLog;
  final StreakState heroStreak;
  final Map<String, StreakState> perPrayerStreaks;
  final StreakState tilawahStreak;
  final List<Quest> quests;
  final String questDate;
  final String lastCheckedDate; // YYYY-MM-DD — last time dailyCheck ran
  final int comebackCount;     // total streak recoveries
  final List<String> badges;   // earned badge IDs

  GameState({
    this.xp = 0, this.level = 1,
    Timings? timings, List<PrayerLog>? prayerLog,
    StreakState? heroStreak, Map<String, StreakState>? perPrayerStreaks,
    StreakState? tilawahStreak, List<Quest>? quests, this.questDate = '',
    this.lastCheckedDate = '', this.comebackCount = 0,
    this.badges = const [],
  })  : timings = timings ?? Timings(),
        prayerLog = prayerLog ?? [],
        heroStreak = heroStreak ?? StreakState(),
        perPrayerStreaks = perPrayerStreaks ?? const {},
        tilawahStreak = tilawahStreak ?? StreakState(),
        quests = quests ?? const [];

  GameState copyWith({
    int? xp, int? level, Timings? timings, List<PrayerLog>? prayerLog,
    StreakState? heroStreak, Map<String, StreakState>? perPrayerStreaks,
    StreakState? tilawahStreak, List<Quest>? quests, String? questDate,
    String? lastCheckedDate, int? comebackCount, List<String>? badges,
  }) => GameState(
      xp: xp ?? this.xp, level: level ?? this.level,
      timings: timings ?? this.timings, prayerLog: prayerLog ?? this.prayerLog,
      heroStreak: heroStreak ?? this.heroStreak,
      perPrayerStreaks: perPrayerStreaks ?? this.perPrayerStreaks,
      tilawahStreak: tilawahStreak ?? this.tilawahStreak,
      quests: quests ?? this.quests, questDate: questDate ?? this.questDate,
      lastCheckedDate: lastCheckedDate ?? this.lastCheckedDate,
      comebackCount: comebackCount ?? this.comebackCount,
      badges: badges ?? this.badges);

  factory GameState.fromMap(Map<String, dynamic> m) {
    final logList = (m['prayerLog'] as List?)?.map((e) => PrayerLog.fromMap(e as Map<String, dynamic>)).toList() ?? [];
    final questList = (m['quests'] as List?)?.map((e) => Quest.fromMap(e as Map<String, dynamic>)).toList() ?? [];
    final pstr = <String, StreakState>{};
    (m['perPrayerStreaks'] as Map<String, dynamic>?)?.forEach((k, v) =>
        pstr[k] = StreakState.fromMap(v as Map<String, dynamic>));
    final badgeList = (m['badges'] as List?)?.cast<String>() ?? [];
    return GameState(
      xp: m['xp'] ?? 0, level: m['level'] ?? 1,
      timings: m['timings'] != null ? Timings.fromMap(m['timings'] as Map<String, dynamic>) : Timings(),
      prayerLog: logList,
      heroStreak: m['heroStreak'] != null ? StreakState.fromMap(m['heroStreak'] as Map<String, dynamic>) : null,
      perPrayerStreaks: pstr,
      tilawahStreak: m['tilawahStreak'] != null ? StreakState.fromMap(m['tilawahStreak'] as Map<String, dynamic>) : null,
      quests: questList, questDate: m['questDate'] ?? '',
      lastCheckedDate: m['lastCheckedDate'] ?? '',
      comebackCount: m['comebackCount'] ?? 0,
      badges: badgeList,
    );
  }
  Map<String, dynamic> toMap() => {
    'xp': xp, 'level': level, 'timings': timings.toMap(),
    'prayerLog': prayerLog.map((e) => e.toMap()).toList(),
    'heroStreak': heroStreak.toMap(),
    'perPrayerStreaks': perPrayerStreaks.map((k, v) => MapEntry(k, v.toMap())),
    'tilawahStreak': tilawahStreak.toMap(),
    'quests': quests.map((e) => e.toMap()).toList(),
    'questDate': questDate,
    'lastCheckedDate': lastCheckedDate,
    'comebackCount': comebackCount,
    'badges': badges,
  };
}

// ─── Game logic (port dari V3 GameViewModel) ───

class GameService {
  static const _key = 'game_state_v1';
  static GameState _cache = GameState();
  static GameState get current => _cache;

  static Future<GameState> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw != null) {
      try { _cache = GameState.fromMap(jsonDecode(raw) as Map<String, dynamic>); } catch (_) {}
    }
    return _cache;
  }

  static Future<void> _save(GameState s) async {
    _cache = s;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(s.toMap()));
  }

  static Future<void> setTimings(Timings t) => _save(_cache.copyWith(timings: t));

  // ─── XP / Level ───
  static int xpNeededForLevel(int level) => (40 + 8 * level + 0.5 * level * level).round();

  static LevelInfo getLevelInfo(int cumulativeXp) {
    var lvl = 1;
    var temp = cumulativeXp;
    while (true) {
      final need = xpNeededForLevel(lvl);
      if (temp >= need) { temp -= need; lvl++; } else {
        return LevelInfo(level: lvl, xpInCurrentLevel: temp,
            xpNeededForNextLevel: need, progress: temp / need);
      }
    }
  }

  static String getRankTitle(int level) {
    String roman(int n) => const {1:'I',2:'II',3:'III',4:'IV',5:'V'}[n] ?? '';
    if (level >= 1 && level <= 9) {
      final div = [5,5,4,4,3,3,2,2,1][level-1];
      return 'Muslim Warrior ${roman(div)}';
    }
    if (level <= 19) return 'Muslim Elite ${roman(5 - ((level-10) ~/ 2))}';
    if (level <= 29) return 'Muslim Master ${roman(5 - ((level-20) ~/ 2))}';
    if (level <= 39) return 'Muslim Grandmaster ${roman(5 - ((level-30) ~/ 2))}';
    if (level <= 59) return 'Muslim Epic ${roman(5 - ((level-40) ~/ 4))}';
    if (level <= 79) return 'Muslim Legend ${roman(5 - ((level-60) ~/ 4))}';
    if (level < 85) return 'Muslim Mythic';
    if (level < 90) return 'Muslim Mythic Honor';
    if (level < 95) return 'Muslim Mythic Glory';
    if (level < 100) return 'Muslim Mythic Immortal';
    return 'Muslim Mythic Immortal ★${level - 99}';
  }

  // ─── Time helpers ───
  static int _toMin(String t) {
    final p = t.split(':');
    if (p.length != 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }
  static int minDiff(String a, String b) => (_toMin(a) - _toMin(b)).abs();
  static bool isBefore(String a, String b) => _toMin(a) < _toMin(b);
  static bool isAfter(String a, String b) => _toMin(a) > _toMin(b);
  static String addMin(String t, int m) {
    final total = ((_toMin(t) + m) % 1440 + 1440) % 1440;
    return '${(total ~/ 60).toString().padLeft(2,'0')}:${(total % 60).toString().padLeft(2,'0')}';
  }
  static String nowHHmm() {
    final d = DateTime.now();
    return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
  static String todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }
  static String yesterdayStr() {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  // ─── Sunnah time-window (port V3) ───
  static bool _isTimeBetweenWrap(String now, String start, String end) {
    final n = _toMin(now), s = _toMin(start), e = _toMin(end);
    if (s <= e) return n >= s && n <= e;
    return n >= s || n <= e;
  }

  static bool isSunnahOnTime(String prayer, Timings t) {
    final now = nowHHmm();
    switch (prayer) {
      case 'dhuha': return isAfter(now, addMin(t.terbit, 15)) && isBefore(now, t.dzuhur);
      case 'tahajjud': return _isTimeBetweenWrap(now, t.isya, t.imsak);
      case 'rawatib_subuh_qobliyah': return isAfter(now, t.subuh) && isBefore(now, t.terbit);
      case 'rawatib_dzuhur_qobliyah': return isAfter(now, t.subuh) && isBefore(now, t.dzuhur);
      case "rawatib_dzuhur_ba'diyyah": return isAfter(now, t.dzuhur) && isBefore(now, t.ashar);
      case 'rawatib_ashar_qobliyah': return isAfter(now, t.dzuhur) && isBefore(now, t.ashar);
      case "rawatib_maghrib_ba'diyyah": return isAfter(now, t.maghrib) && isBefore(now, t.isya);
      case "rawatib_isya_ba'diyyah": return isAfter(now, t.isya) && isBefore(now, addMin(t.isya, 300));
      default: return true;
    }
  }

  static String sunnahHint(String prayer) => switch (prayer) {
    'dhuha' => 'Dhuha bisa setelah matahari naik (±15 min setelah terbit) sampai sebelum Dzuhur.',
    'tahajjud' => 'Tahajjud waktu setelah Isya sampai sebelum Imsak.',
    'rawatib_subuh_qobliyah' => 'Qobliyah Subuh waktunya sama dengan sholat Subuh (dari Subuh sampai Terbit).',
    'rawatib_dzuhur_qobliyah' => 'Qobliyah Dzuhur waktunya setelah Subuh sampai sebelum adzan Dzuhur.',
    "rawatib_dzuhur_ba'diyyah" => "Ba'diyah Dzuhur waktunya setelah Dzuhur sampai sebelum Ashar.",
    'rawatib_ashar_qobliyah' => 'Qobliyah Ashar waktunya setelah Dzuhur sampai sebelum adzan Ashar.',
    "rawatib_maghrib_ba'diyyah" => "Ba'diyah Maghrib waktunya setelah Maghrib sampai sebelum Isya.",
    "rawatib_isya_ba'diyyah" => "Ba'diyah Isya waktunya setelah Isya sampai tengah malam.",
    _ => 'Coba lagi nanti ya.',
  };

  static bool isPrayerWindowOpen(String prayer, Timings t) {
    final now = nowHHmm();
    switch (prayer) {
      case 'subuh': return isAfter(now, t.subuh);
      case 'dzuhur': return isAfter(now, t.dzuhur);
      case 'ashar': return isAfter(now, t.ashar);
      case 'maghrib': return isAfter(now, t.maghrib);
      case 'isya': return isAfter(now, t.isya);
      default: return true;
    }
  }

  static bool isCurrentOrUpcoming(String prayer, Timings t) {
    final now = nowHHmm();
    final wajib = [('subuh', t.subuh), ('dzuhur', t.dzuhur), ('ashar', t.ashar),
                   ('maghrib', t.maghrib), ('isya', t.isya)];
    for (final (name, time) in wajib) {
      if (name == prayer) return isAfter(time, now);
    }
    return false;
  }

  static StreakState _updStreak(StreakState s, String today, String yest) {
    if (s.lastDate == today) return s;
    final cur = s.lastDate == yest ? s.current + 1 : 1;
    return StreakState(current: cur, best: cur > s.best ? cur : s.best, lastDate: today);
  }

  static String _adzanFor(String prayer, Timings t) => switch (prayer) {
    'subuh' => t.subuh, 'dzuhur' => t.dzuhur, 'ashar' => t.ashar,
    'maghrib' => t.maghrib, 'isya' => t.isya, _ => '',
  };

  /// Re-evaluate daily quest progress from today's prayer logs.
  /// Preserves claimed quests (they stay as-is).
  static List<Quest> _reevaluateQuests(
      List<Quest> current, List<PrayerLog> logs, StreakState hero, Timings t) {
    final today = todayStr();
    final todayLogs = logs.where((l) => l.date == today).toList();
    final wajibLogs = todayLogs
        .where((l) => wajibList.contains(l.prayer))
        .toList();

    PrayerLog? findLog(String prayer) {
      for (final l in todayLogs) {
        if (l.prayer == prayer) return l;
      }
      return null;
    }

    return current.map((q) {
      if (q.claimed) return q;
      var prog = 0;
      var done = false;
      switch (q.id) {
        case 'quest_subuh_tepat':
          final subuhLog = findLog('subuh');
          if (subuhLog != null && t.subuh.isNotEmpty &&
              minDiff(subuhLog.time, t.subuh) <= 30) {
            prog = 1;
            done = true;
          }
          break;
        case 'quest_five_rings':
          if (wajibList.every((p) =>
              todayLogs.any((l) => l.prayer == p))) {
            prog = 1;
            done = true;
          }
          break;
        case 'quest_timely_prayers':
          prog = wajibLogs.where((l) {
            final adzan = _adzanFor(l.prayer, t);
            return adzan.isNotEmpty && minDiff(l.time, adzan) <= 10;
          }).length.clamp(0, 3);
          done = prog >= 3;
          break;
        case 'quest_dhuha_before_dzuhur':
          final dhuhaLog = findLog('dhuha');
          if (dhuhaLog != null && isBefore(dhuhaLog.time, t.dzuhur)) {
            prog = 1;
            done = true;
          }
          break;
        case 'quest_tilawah_today':
          if (todayLogs.any((l) => l.prayer == 'tilawah')) {
            prog = 1;
            done = true;
          }
          break;
        case 'quest_rawatib_two':
          final cnt = todayLogs.where((l) => l.prayer.startsWith('rawatib')).length;
          prog = cnt.clamp(0, 2);
          done = cnt >= 2;
          break;
        case 'quest_hero_streak_7':
          prog = hero.current.clamp(0, 7);
          done = hero.current >= 7;
          break;
      }
      return q.copyWith(progress: prog, completed: done);
    }).toList();
  }

  // ─── Log prayer (core V3 logic) ───
  /// Returns (newState, xpGained, didLevelUp) or null if rejected (already logged / not on time).
  static (GameState, int, bool)? logPrayer(GameState state, String prayer, String type) {
    final today = todayStr();
    final yest = yesterdayStr();
    final now = nowHHmm();

    if (state.prayerLog.any((l) => l.date == today && l.prayer == prayer)) return null;

    if (type == 'sunnah' && !isSunnahOnTime(prayer, state.timings)) return null;

    final newLog = PrayerLog(date: today, prayer: prayer, time: now, type: type);
    final updatedLogs = [...state.prayerLog, newLog];

    var xpGained = switch (prayer) {
      'subuh' => 30, 'dzuhur' => 20, 'ashar' => 20, 'maghrib' => 25, 'isya' => 25, _ => 15,
    };

    final wajibList = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
    final isHeroCompletor = type == 'wajib' &&
        wajibList.every((p) => p == prayer || updatedLogs.any((l) => l.date == today && l.prayer == p));
    if (isHeroCompletor) xpGained += 50;

    if (type == 'wajib') {
      final adzanTime = switch (prayer) {
        'subuh' => state.timings.subuh, 'dzuhur' => state.timings.dzuhur,
        'ashar' => state.timings.ashar, 'maghrib' => state.timings.maghrib,
        'isya' => state.timings.isya, _ => '',
      };
      if (adzanTime.isNotEmpty && minDiff(now, adzanTime) <= 30) xpGained += 15;
    }

    final oldInfo = getLevelInfo(state.xp);
    final newInfo = getLevelInfo(state.xp + xpGained);
    final didLevelUp = newInfo.level > oldInfo.level;

    var hero = state.heroStreak;
    var pstr = Map<String, StreakState>.from(state.perPrayerStreaks);
    var tilawah = state.tilawahStreak;

    if (type == 'wajib' && wajibList.contains(prayer)) {
      pstr[prayer] = _updStreak(pstr[prayer] ?? StreakState(), today, yest);
    }
    if (isHeroCompletor) hero = _updStreak(hero, today, yest);
    if (prayer == 'tilawah') tilawah = _updStreak(tilawah, today, yest);

    // Update quest progress
    var quests = state.quests.map((q) {
      var prog = q.progress; var done = q.completed;
      switch (q.id) {
        case 'quest_subuh_tepat':
          if (prayer == 'subuh' && minDiff(now, state.timings.subuh) <= 30) { prog = 1; done = true; }
          break;
        case 'quest_five_rings':
          if (isHeroCompletor) { prog = 1; done = true; }
          break;
        case 'quest_dhuha_before_dzuhur':
          if (prayer == 'dhuha' && isBefore(now, state.timings.dzuhur)) { prog = 1; done = true; }
          break;
        case 'quest_tilawah_today':
          if (prayer == 'tilawah') { prog = 1; done = true; }
          break;
        case 'quest_hero_streak_7':
          prog = hero.current;
          if (hero.current >= 7) done = true;
          break;
        case 'quest_timely_prayers':
          final adzan = switch (prayer) {
            'subuh' => state.timings.subuh, 'dzuhur' => state.timings.dzuhur,
            'ashar' => state.timings.ashar, 'maghrib' => state.timings.maghrib,
            'isya' => state.timings.isya, _ => '',
          };
          if (adzan.isNotEmpty && minDiff(now, adzan) <= 10) {
            prog = (prog + 1).clamp(0, 3);
            if (prog >= 3) done = true;
          }
          break;
        case 'quest_rawatib_two':
          if (prayer.startsWith('rawatib')) {
            final cnt = updatedLogs.where((l) => l.date == today && l.prayer.startsWith('rawatib')).length;
            prog = cnt.clamp(0, 2);
            if (cnt >= 2) done = true;
          }
          break;
      }
      return q.copyWith(progress: prog, completed: done);
    }).toList();

    final newState = state.copyWith(
      xp: state.xp + xpGained, level: newInfo.level,
      prayerLog: updatedLogs, heroStreak: hero,
      perPrayerStreaks: pstr, tilawahStreak: tilawah, quests: quests,
    );
    return (newState, xpGained, didLevelUp);
  }

  static Future<(GameState, int, bool)?> logPrayerAsync(String prayer, String type) async {
    final res = logPrayer(_cache, prayer, type);
    if (res == null) return null;
    await _save(res.$1);
    await refreshBadges(); // check badge unlock
    return (current, res.$2, res.$3);
  }

  static Future<GameState> unlogPrayer(String prayer) async {
    final today = todayStr();
    final logItem = _cache.prayerLog
        .where((l) => l.date == today && l.prayer == prayer)
        .firstOrNull;
    if (logItem == null) return _cache;

    var xpLost = switch (prayer) {
      'subuh' => 30, 'dzuhur' => 20, 'ashar' => 20,
      'maghrib' => 25, 'isya' => 25, _ => 15,
    };

    // Apakah sebelum unlog ini 5/5 sudah lengkap? Kalau iya, prayer ini yang
    // memicu hero bonus +50 XP.
    final wasFullBefore = wajibList.every((p) =>
        _cache.prayerLog.any((l) => l.date == today && l.prayer == p));
    if (wasFullBefore) xpLost += 50;

    // Kembalikan timely bonus +15 XP kalau wajib dan masih ≤30 menit setelah adzan.
    if (logItem.type == 'wajib') {
      final adzan = _adzanFor(prayer, _cache.timings);
      if (adzan.isNotEmpty && minDiff(logItem.time, adzan) <= 30) xpLost += 15;
    }

    final newXp = (_cache.xp - xpLost).clamp(0, 999999);
    final newInfo = getLevelInfo(newXp);
    final updatedLogs = _cache.prayerLog
        .where((l) => !(l.date == today && l.prayer == prayer))
        .toList();

    // Revert streaks (hanya untuk hari ini, karena unlogPrayer V1 hanya hari ini)
    var hero = _cache.heroStreak;
    var pstr = Map<String, StreakState>.from(_cache.perPrayerStreaks);
    var tilawah = _cache.tilawahStreak;

    if (logItem.type == 'wajib' && wajibList.contains(prayer)) {
      final s = pstr[prayer] ?? StreakState();
      pstr[prayer] = s.copyWith(
          current: (s.current - 1).clamp(0, 999999), lastDate: '');
    }
    if (wasFullBefore) {
      hero = hero.copyWith(
          current: (hero.current - 1).clamp(0, 999999), lastDate: '');
    }
    if (prayer == 'tilawah') {
      tilawah = tilawah.copyWith(
          current: (tilawah.current - 1).clamp(0, 999999), lastDate: '');
    }

    final quests = _reevaluateQuests(_cache.quests, updatedLogs, hero, _cache.timings);

    final newState = _cache.copyWith(
      xp: newXp,
      level: newInfo.level,
      prayerLog: updatedLogs,
      heroStreak: hero,
      perPrayerStreaks: pstr,
      tilawahStreak: tilawah,
      quests: quests,
    );
    await _save(newState);
    await refreshBadges(); // re-evaluate after unlog
    return current;
  }

  /// Claim a completed quest. Returns new state and whether the user leveled up.
  static Future<(GameState, bool)> claimQuest(String questId) async {
    final q = _cache.quests.where((x) => x.id == questId).firstOrNull;
    if (q == null || !q.completed || q.claimed) return (_cache, false);
    final oldInfo = getLevelInfo(_cache.xp);
    final quests = _cache.quests.map((x) => x.id == questId ? x.copyWith(claimed: true) : x).toList();
    final newXp = _cache.xp + q.xpReward;
    final newInfo = getLevelInfo(newXp);
    final newState = _cache.copyWith(
      xp: newXp, level: newInfo.level, quests: quests);
    await _save(newState);
    await refreshBadges(); // level-up may unlock mythic_reached
    return (current, newInfo.level > oldInfo.level);
  }

  /// Add arbitrary XP (e.g. from learning modules). Returns new state + didLevelUp.
  static Future<(GameState, bool)> addXp(int amount) async {
    final oldInfo = getLevelInfo(_cache.xp);
    final newInfo = getLevelInfo(_cache.xp + amount);
    final newState = _cache.copyWith(
      xp: _cache.xp + amount, level: newInfo.level);
    await _save(newState);
    return (newState, newInfo.level > oldInfo.level);
  }

  // ─── Quest generation (V3 pool, pick 5 random) ───
  static List<Quest> generateQuestPool() {
    final pool = [
      Quest(id: 'quest_subuh_tepat', desc: 'Sholat Subuh tepat waktu (≤30 menit setelah adzan)', xpReward: 50, target: 1, progress: 0, completed: false, claimed: false),
      Quest(id: 'quest_five_rings', desc: 'Lengkapin 5/5 sholat hari ini', xpReward: 100, target: 1, progress: 0, completed: false, claimed: false),
      Quest(id: 'quest_tilawah_today', desc: 'Tilawah/Dzikir hari ini', xpReward: 30, target: 1, progress: 0, completed: false, claimed: false),
      Quest(id: 'quest_timely_prayers', desc: 'Sholat tepat waktu (≤10 menit), 3x hari ini', xpReward: 60, target: 3, progress: 0, completed: false, claimed: false),
      Quest(id: 'quest_dhuha_before_dzuhur', desc: 'Sholat Dhuha sebelum Dzuhur', xpReward: 40, target: 1, progress: 0, completed: false, claimed: false),
      Quest(id: 'quest_rawatib_two', desc: 'Rawatib 2x hari ini', xpReward: 45, target: 2, progress: 0, completed: false, claimed: false),
    ];
    if (_cache.heroStreak.current >= 6) {
      pool.add(Quest(id: 'quest_hero_streak_7', desc: 'Pertahanin Hero Streak 7 hari! 🔥',
          xpReward: 200, target: 7, progress: _cache.heroStreak.current,
          completed: _cache.heroStreak.current >= 7, claimed: false));
    }
    pool.shuffle();
    return pool.take(5).toList();
  }

  // ─── Badge system (13 badges) ───
  // Port dari GameViewModel.evaluateBadges() (main Kotlin).
  // Setiap aksi yang mengubah state (logPrayer, unlogPrayer, claimQuest, runDailyCheck)
  // harus memanggil _evaluateBadges() untuk update badge yang earned.

  static const badgeDefs = <(String id, String title, String emoji, String desc)>[
    ('langkah_pertama',  'LANGKAH PERTAMA',   '🌱', 'Log sholat pertama kamu'),
    ('subuh_warrior',    'SUBUH WARRIOR',     '🕌', 'Streak Subuh 7 hari'),
    ('subuh_legend',     'SUBUH LEGEND',      '⭐', 'Streak Subuh 30 hari'),
    ('five_five_master', '5/5 MASTER',        '🏆', 'Selesaikan 5 wajib 1 hari'),
    ('five_five_streak_7','5/5 STREAK x7',    '🔥', 'Streak 5/5 selama 7 hari'),
    ('five_five_streak_30','5/5 STREAK x30',  '💎', 'Streak 5/5 selama 30 hari'),
    ('sultan_sunnah',    'SULTAN SUNNAH',     '🤲', '50 sunnah total'),
    ('tilawah_streak_14','TILAWAH STREAK',    '📖', 'Streak Tilawah 14 hari'),
    ('ramadan_champion', 'RAMADAN CHAMPION',  '🌙', 'Aktif di bulan Ramadan'),
    ('comeback_king',    'COMEBACK KING',     '🛡', 'Comeback 3x setelah streak putus'),
    ('early_bird',       'EARLY BIRD',        '⏱', '20x sholat tepat waktu (±10m)'),
    ('mythic_reached',   'MYTHIC REACHED',    '👑', 'Capai level 80 (Muslim Mythic)'),
    ('santri_digital',   'SANTRI DIGITAL',    '📚', 'Selesaikan 16 modul Belajar'),
  ];

  /// Evaluasi semua badge. Return list of newly earned badge IDs.
  static List<String> evaluateBadges(GameState state) {
    final earned = state.badges.toSet();

    // 1. Langkah Pertama
    if (state.prayerLog.isNotEmpty) earned.add('langkah_pertama');

    // 2. Subuh Warrior (streak ≥ 7)
    final subuhStrk = state.perPrayerStreaks['subuh']?.current ?? 0;
    if (subuhStrk >= 7) earned.add('subuh_warrior');

    // 3. Subuh Legend (streak ≥ 30)
    if (subuhStrk >= 30) earned.add('subuh_legend');

    // 4. 5/5 Master (hero streak ≥ 1)
    final heroStrk = state.heroStreak.current;
    if (heroStrk >= 1) earned.add('five_five_master');

    // 5. 5/5 Streak x7
    if (heroStrk >= 7) earned.add('five_five_streak_7');

    // 6. 5/5 Streak x30
    if (heroStrk >= 30) earned.add('five_five_streak_30');

    // 7. Sultan Sunnah (50 sunnah total)
    final sunnahCount = state.prayerLog.where((l) => l.type == 'sunnah').length;
    if (sunnahCount >= 50) earned.add('sultan_sunnah');

    // 8. Tilawah Streak (14 hari)
    final tilawahStrk = state.tilawahStreak.current;
    if (tilawahStrk >= 14) earned.add('tilawah_streak_14');

    // 9. Ramadan Champion — log sholat hari ini (aktif beribadah)
    final today = todayStr();
    if (state.prayerLog.any((l) => l.date == today)) {
      earned.add('ramadan_champion');
    }

    // 10. Comeback King (comebackCount ≥ 3)
    if (state.comebackCount >= 3) earned.add('comeback_king');

    // 11. Early Bird (20x tepat waktu ±10 menit dari adzan)
    final timelyCount = state.prayerLog.where((l) {
      if (l.type != 'wajib') return false;
      final adzan = _adzanFor(l.prayer, state.timings);
      return adzan.isNotEmpty && minDiff(l.time, adzan) <= 10;
    }).length;
    if (timelyCount >= 20) earned.add('early_bird');

    // 12. Mythic Reached (level ≥ 80)
    if (state.level >= 80) earned.add('mythic_reached');

    // 13. Santri Digital — selesaikan 16 modul Belajar
    // TODO: aktifkan setelah Gap learning system di-port
    // final completedModules = state.learningProgress.where((m) => m.completed).length;
    // if (completedModules >= 16) earned.add('santri_digital');

    return earned.toList()..sort((a, b) =>
        badgeDefs.indexWhere((d) => d.$1 == a)
            .compareTo(badgeDefs.indexWhere((d) => d.$1 == b)));
  }

  /// Eval + save badges. Return newly earned badges (for toast notification).
  static Future<List<String>> refreshBadges() async {
    final before = _cache.badges.toSet();
    final after = evaluateBadges(_cache);
    final newBadges = after.where((b) => !before.contains(b)).toList();
    if (newBadges.isNotEmpty) {
      await _save(_cache.copyWith(badges: after));
    }
    return newBadges;
  }

  // ─── Daily check: streak recovery + comeback counter ───
  // Port dari GameViewModel.runDailyCheckAndRefresh() (main branch Kotlin).
  // Evaluasi hari² yang terlewat antara lastCheckedDate → today.
  // Untuk setiap hari yang missed: pakai freeze jika ada, atau recovery (×0.75) + comebackCount++.
  // Setiap awal minggu (ISO week berbeda), reset freezeAvailable = true untuk semua streak.
  static Future<GameState> runDailyCheck() async {
    final state = _cache;
    final today = todayStr();

    // Already checked today → skip
    if (state.lastCheckedDate == today) {
      // Make sure quests are generated for today
      if (state.questDate != today) {
        return ensureDailyQuests();
      }
      return state;
    }

    // First-time init
    if (state.lastCheckedDate.isEmpty) {
      final init = state.copyWith(lastCheckedDate: today, questDate: today);
      await _save(init);
      return ensureDailyQuests();
    }

    final lastChecked = DateTime.parse(state.lastCheckedDate);
    final todayDate = DateTime.parse(today);

    var hero = state.heroStreak;
    var tilawah = state.tilawahStreak;
    var tracker = Map<String, StreakState>.from(state.perPrayerStreaks);
    // Ensure all 5 wajib keys exist
    for (final p in wajibList) {
      tracker.putIfAbsent(p, () => StreakState());
    }
    var comeback = state.comebackCount;

    // Week rotation: reset freezeAvailable if different ISO week
    if (_isDifferentWeek(lastChecked, todayDate)) {
      hero = hero.copyWith(freezeAvailable: true);
      tilawah = tilawah.copyWith(freezeAvailable: true);
      for (final k in tracker.keys) {
        tracker[k] = tracker[k]!.copyWith(freezeAvailable: true);
      }
    }

    // Evaluate missed days: lastChecked+1 .. today-1 (exclusive of today)
    var evalDate = lastChecked.add(const Duration(days: 1));
    while (evalDate.isBefore(todayDate)) {
      final evalStr = _dateKey(evalDate);
      hero = _evalStreakMissed(hero, _allWajibLoggedForDate(state, evalStr), evalStr);
      tilawah = _evalStreakMissed(tilawah, _prayerLoggedForDate(state, evalStr, 'tilawah'), evalStr);
      for (final p in tracker.keys) {
        tracker[p] = _evalStreakMissed(tracker[p]!, _prayerLoggedForDate(state, evalStr, p), evalStr);
      }
      evalDate = evalDate.add(const Duration(days: 1));
    }

    // Count recoveries (compare before/after)
    final heroRecoveries = _countRecovery(state.heroStreak, hero);
    final tilawahRecoveries = _countRecovery(state.tilawahStreak, tilawah);
    var prayerRecoveries = 0;
    for (final k in tracker.keys) {
      prayerRecoveries += _countRecovery(state.perPrayerStreaks[k] ?? StreakState(), tracker[k]!);
    }
    comeback += heroRecoveries + tilawahRecoveries + prayerRecoveries;

    final updated = state.copyWith(
      heroStreak: hero,
      perPrayerStreaks: tracker,
      tilawahStreak: tilawah,
      comebackCount: comeback,
      lastCheckedDate: today,
    );
    await _save(updated);
    await refreshBadges(); // comeback_king may unlock

    // Generate fresh quests for today if needed
    if (updated.questDate != today) {
      return ensureDailyQuests();
    }
    return current;
  }

  /// Apply missed-day penalty to a single streak.
  /// If [logged] is true, no penalty. If freezeAvailable, consume freeze.
  /// Else recovery: current × 0.75 (min 1 if was >0), mark comeback.
  static StreakState _evalStreakMissed(StreakState s, bool logged, String evalDate) {
    if (logged || s.lastDate == evalDate) return s;
    if (s.freezeAvailable) {
      return s.copyWith(freezeAvailable: false, lastDate: evalDate);
    }
    if (s.current > 0) {
      final recovered = (s.current * 0.75).floor().clamp(1, s.current);
      return s.copyWith(current: recovered);
    }
    return s;
  }

  static int _countRecovery(StreakState before, StreakState after) {
    // Recovery = current decreased without freeze consumption
    if (after.current < before.current && after.freezeAvailable == before.freezeAvailable) {
      return 1;
    }
    return 0;
  }

  static bool _allWajibLoggedForDate(GameState state, String date) {
    return wajibList.every((p) =>
        state.prayerLog.any((l) => l.date == date && l.prayer == p));
  }

  static bool _prayerLoggedForDate(GameState state, String date, String prayer) {
    return state.prayerLog.any((l) => l.date == date && l.prayer == prayer);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Check if two dates are in different ISO weeks.
  /// ISO week: Monday = start of week. Week 1 = first week with Thursday.
  static bool _isDifferentWeek(DateTime a, DateTime b) {
    // Find Monday of each date's week
    final aMonday = a.subtract(Duration(days: a.weekday - 1));
    final bMonday = b.subtract(Duration(days: b.weekday - 1));
    return aMonday != bMonday;
  }

  static Future<GameState> ensureDailyQuests() async {
    if (_cache.questDate == todayStr() && _cache.quests.isNotEmpty) return _cache;
    final quests = generateQuestPool();
    final newState = _cache.copyWith(quests: quests, questDate: todayStr());
    await _save(newState);
    return newState;
  }

  // ─── Derived getters ───
  static const wajibList = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

  static int get checkedWajibToday =>
      wajibList.where((p) => _cache.prayerLog.any((l) => l.date == todayStr() && l.prayer == p)).length;

  static int get sunnahCountToday => _cache.prayerLog
      .where((l) => l.date == todayStr() && (l.type == 'sunnah' || l.prayer.startsWith('rawatib')))
      .length;

  static bool get tilawahDoneToday =>
      _cache.prayerLog.any((l) => l.date == todayStr() && l.prayer == 'tilawah');

  static bool isPrayerCheckedToday(String prayer) =>
      _cache.prayerLog.any((l) => l.date == todayStr() && l.prayer == prayer);

  static String nextPrayerInfo(Timings t) {
    final now = nowHHmm();
    final list = [('Subuh', t.subuh), ('Dzuhur', t.dzuhur), ('Ashar', t.ashar),
                  ('Maghrib', t.maghrib), ('Isya', t.isya)];
    for (final (n, time) in list) {
      if (isAfter(time, now)) {
        final diff = minDiff(time, now);
        final h = diff ~/ 60, m = diff % 60;
        return '$n|$time|${h > 0 ? '${h}j ${m}m' : '${m}m'} lagi';
      }
    }
    return 'Subuh|${t.subuh}|besok';
  }
}

// ponytail: self-check
void main() {
  // Level curve sanity
  assert(GameService.xpNeededForLevel(1) == 48 || GameService.xpNeededForLevel(1) == 49);
  final info = GameService.getLevelInfo(0);
  assert(info.level == 1 && info.progress == 0);
  final info2 = GameService.getLevelInfo(1000);
  assert(info2.level >= 5);
  // ignore: avoid_print
  print('GameService OK: level 0→${info.level}, 1000xp→${info2.level}');
}
