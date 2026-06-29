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
  StreakState({this.current = 0, this.best = 0, this.lastDate = ''});
  StreakState copyWith({int? current, int? best, String? lastDate}) => StreakState(
        current: current ?? this.current,
        best: best ?? this.best,
        lastDate: lastDate ?? this.lastDate,
      );
  factory StreakState.fromMap(Map<String, dynamic> m) => StreakState(
        current: m['current'] ?? 0, best: m['best'] ?? 0, lastDate: m['lastDate'] ?? '');
  Map<String, dynamic> toMap() => {'current': current, 'best': best, 'lastDate': lastDate};
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

  GameState({
    this.xp = 0, this.level = 1,
    Timings? timings, List<PrayerLog>? prayerLog,
    StreakState? heroStreak, Map<String, StreakState>? perPrayerStreaks,
    StreakState? tilawahStreak, List<Quest>? quests, this.questDate = '',
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
  }) => GameState(
      xp: xp ?? this.xp, level: level ?? this.level,
      timings: timings ?? this.timings, prayerLog: prayerLog ?? this.prayerLog,
      heroStreak: heroStreak ?? this.heroStreak,
      perPrayerStreaks: perPrayerStreaks ?? this.perPrayerStreaks,
      tilawahStreak: tilawahStreak ?? this.tilawahStreak,
      quests: quests ?? this.quests, questDate: questDate ?? this.questDate);

  factory GameState.fromMap(Map<String, dynamic> m) {
    final logList = (m['prayerLog'] as List?)?.map((e) => PrayerLog.fromMap(e as Map<String, dynamic>)).toList() ?? [];
    final questList = (m['quests'] as List?)?.map((e) => Quest.fromMap(e as Map<String, dynamic>)).toList() ?? [];
    final pstr = <String, StreakState>{};
    (m['perPrayerStreaks'] as Map<String, dynamic>?)?.forEach((k, v) =>
        pstr[k] = StreakState.fromMap(v as Map<String, dynamic>));
    return GameState(
      xp: m['xp'] ?? 0, level: m['level'] ?? 1,
      timings: m['timings'] != null ? Timings.fromMap(m['timings'] as Map<String, dynamic>) : Timings(),
      prayerLog: logList,
      heroStreak: m['heroStreak'] != null ? StreakState.fromMap(m['heroStreak'] as Map<String, dynamic>) : null,
      perPrayerStreaks: pstr,
      tilawahStreak: m['tilawahStreak'] != null ? StreakState.fromMap(m['tilawahStreak'] as Map<String, dynamic>) : null,
      quests: questList, questDate: m['questDate'] ?? '',
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
    return res;
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
    return newState;
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
    return (newState, newInfo.level > oldInfo.level);
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
