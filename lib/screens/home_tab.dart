import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tier_avatar.dart';
import '../../services/game_service.dart';
import '../../services/prayer_service.dart';
import '../../services/notification_service.dart';
import '../../services/achievement_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/achievement_medal.dart';
import 'naik_level_screen.dart';

extension _StringExt on String {
  String get cap => '${this[0].toUpperCase()}${substring(1)}';
}

/// Home / Dashboard Utama — live game logic (port V3), design preserved.
class HomeTab extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  const HomeTab({super.key, this.onSettingsPressed});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GameState _state = GameState();
  String _nickname = 'Pejuang';
  Timer? _tick;
  String _claimingQuestId = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    // ponytail: load in background; never block the first paint
    _load(showLoading: false);
    _tick = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
    // Kota diganti dari tab jadwal/profil → refetch timing kota baru
    // (sekalian reschedule notif adzan di _fetchTimingsSilently).
    PrayerService.locationVersion.addListener(_onLocationChanged);
    themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    _tick?.cancel();
    PrayerService.locationVersion.removeListener(_onLocationChanged);
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _onLocationChanged() async {
    await _fetchTimingsSilently();
    if (mounted) setState(() => _state = GameService.current);
  }

  Future<void> _load({bool showLoading = true}) async {
    _error = '';
    try {
      await GameService.load();
      await GameService.runDailyCheck();
      await GameService.ensureDailyQuests();
      // Backfill diam-diam: progress lama (mis. streak sebelum update app)
      // langsung terisi di grid profil tanpa memberondong popup saat buka.
      await AchievementService.refresh();
      final p = await SharedPreferences.getInstance();
      await _fetchTimingsSilently();
      if (mounted) {
        setState(() {
          _state = GameService.current;
          _nickname = p.getString('nickname') ?? 'Pejuang';
        });
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('HOME_LOAD_ERROR: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      // ponytail: no loading flag to reset
    }
  }

  Future<void> _fetchTimingsSilently() async {
    try {
      final loc = await PrayerService.loadLocation();
      if (loc == null) return;
      final j = await PrayerService.fetchSchedule(cityId: loc.id).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (j != null) {
        await GameService.setTimings(Timings(
          imsak: j['imsak'] ?? '04:30',
          subuh: j['subuh'] ?? '04:42',
          terbit: j['terbit'] ?? '05:55',
          dhuha: j['dhuha'] ?? '06:20',
          dzuhur: j['dzuhur'] ?? '12:01',
          ashar: j['ashar'] ?? '15:20',
          maghrib: j['maghrib'] ?? '17:55',
          isya: j['isya'] ?? '19:08',
        ));
        // Schedule adhan reminders if enabled
        if (await NotificationService.isRemindersEnabled()) {
          await NotificationService.scheduleAdhanReminders(loc.name, {
            'subuh': j['subuh'] ?? '04:42',
            'dzuhur': j['dzuhur'] ?? '12:01',
            'ashar': j['ashar'] ?? '15:20',
            'maghrib': j['maghrib'] ?? '17:55',
            'isya': j['isya'] ?? '19:08',
          });
        }
      }
    } catch (_) {
      // ponytail: timings are optional; never let this block home
    }
  }

  Future<void> _togglePrayer(String prayer, String type) async {
    // Di luar window (mis. Subuh lewat 3 jam dari adzan) status beku —
    // tidak bisa dicentang ataupun dibatalkan lagi.
    if (type == 'wajib' &&
        !GameService.isPrayerWindowOpen(prayer, _state.timings)) {
      _toast('🔒 ${GameService.wajibLockHint(prayer, _state.timings)}');
      return;
    }
    final isLogged = GameService.isPrayerCheckedToday(prayer);
    if (isLogged) {
      final s = await GameService.unlogPrayer(prayer);
      setState(() => _state = s);
      return;
    }
    if (type == 'sunnah' && !GameService.isSunnahOnTime(prayer, _state.timings)) {
      _toast('⏰ ${GameService.sunnahHint(prayer)}');
      return;
    }
    final res = await GameService.logPrayerAsync(prayer, type);
    if (res == null) {
      _toast('Sholat ini udah dicatat hari ini!');
      return;
    }
    setState(() => _state = res.$1);
    final (_, xp, levelsGained) = res;
    _toast('+$xp XP!${levelsGained > 0 ? " 🎉 LEVEL UP!" : ""}');
    // Announcer achievement tampil dulu (di home), baru layar naik level.
    final newAch = await AchievementService.refresh();
    for (final a in newAch) {
      if (!mounted) break;
      await showAchievementUnlock(context, a);
    }
    if (levelsGained > 0 && mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NaikLevelScreen(xpGained: xp, levelsGained: levelsGained),
      ));
    }
  }

  Future<void> _claimQuest(Quest q) async {
    if (!q.completed || q.claimed || _claimingQuestId.isNotEmpty) return;
    setState(() => _claimingQuestId = q.id);
    final (s, levelsGained) = await GameService.claimQuest(q.id);
    if (!mounted) return;
    setState(() {
      _state = s;
      _claimingQuestId = '';
    });
    _toast('+${q.xpReward} XP dari quest!', top: true);
    // XP quest bisa memicu medali rank (WARRIOR..MYTHIC).
    final newAch = await AchievementService.refresh();
    for (final a in newAch) {
      if (!mounted) break;
      await showAchievementUnlock(context, a);
    }
    if (levelsGained > 0 && mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NaikLevelScreen(xpGained: q.xpReward, levelsGained: levelsGained),
      ));
    }
  }

  void _toast(String msg, {bool top = false}) {
    final screenHeight = MediaQuery.of(context).size.height;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppText.bodyMd().copyWith(color: AppColors.onSurface)),
      backgroundColor: AppColors.surfaceContainerLowest,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: top ? EdgeInsets.only(bottom: screenHeight - 80) : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final info = GameService.getLevelInfo(_state.xp);
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _load(showLoading: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 100),
            children: [
              _section(0, _appBar(context)),
              const SizedBox(height: AppSpacing.md),
              _section(1, _heroRank(info)),
              const SizedBox(height: AppSpacing.sm),
              _section(2, _hudStrip()),
              const SizedBox(height: AppSpacing.lg),
              _section(3, _ritualRings()),
              const SizedBox(height: AppSpacing.lg),
              _section(4, _prayerQuests()),
              const SizedBox(height: AppSpacing.lg),
              _section(5, _dailyChest()),
              const SizedBox(height: AppSpacing.lg),
              _section(6, _bonusQuest()),
              const SizedBox(height: AppSpacing.lg),
              if (_state.quests.isNotEmpty) _section(7, _questList()),
              if (_state.quests.isNotEmpty) const SizedBox(height: AppSpacing.lg),
              _section(8, _sideQuest(context)),
              const SizedBox(height: AppSpacing.lg),
              _section(9, _dailyBento()),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('DEBUG: $_error', style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Staggered entrance wrapper — each home section fades/slides in sequence.
  Widget _section(int index, Widget child) {
    return Entrance(
      delay: Duration(milliseconds: 60 * index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: child,
      ),
    );
  }

  // ── HUD chrome budget ─────────────────────────────────────────────
  // Redesign minimalis: glow & border HANYA di (1) hero Status Window,
  // (2) baris "aktif sekarang" (cyan hairline), (3) shimmer claimable.
  // Kartu tenang pakai FlatCard, header pakai HudHeader (common.dart).

  Widget _appBar(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/logo.png', width: 22, height: 22),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'MUSLIM LEVELING',
          style: AppText.labelCaps()
              .copyWith(color: AppColors.onSurface, fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.settings_outlined,
              color: AppColors.onSurfaceVariant),
          onPressed: widget.onSettingsPressed,
        ),
      ],
    );
  }

  Widget _heroRank(LevelInfo info) {
    final tier = getTierVisualConfig(getTierName(info.level));
    final light = isLightTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // Outer glow: dark only — light uses solid surface + border.
        boxShadow: light
            ? null
            : [
                BoxShadow(
                  color: tier.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            // Light: solid raised surface. Dark: translucent tier gradient.
            color: light ? AppColors.surfaceContainerLow : null,
            gradient: light
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tier.primaryColor.withValues(alpha: 0.14),
                      AppColors.surfaceContainer.withValues(alpha: 0.75),
                      tier.secondaryColor.withValues(alpha: 0.08),
                    ],
                  ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: tier.primaryColor.withValues(alpha: light ? 0.55 : 0.45),
              width: light ? 1.0 : 1.5,
            ),
          ),
          child: Stack(
            children: [
              // subtle Islamic geometric lattice, tinted by tier
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GeoPatternPainter(tier.primaryColor)),
                ),
              ),
              if (!light)
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tier.primaryColor.withValues(alpha: 0.10),
                      boxShadow: [
                        BoxShadow(
                          color: tier.secondaryColor.withValues(alpha: 0.12),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CURRENT RANK', style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            // Light: bright tier colors (some are white/gold)
                            // vanish on the near-white card — use solid ink.
                            // Dark: keep the tier gradient (gaming identity).
                            isLightTheme
                                ? Text(
                                    GameService.getRankTitle(info.level),
                                    style: AppText.headlineMd()
                                        .copyWith(color: AppColors.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : ShaderMask(
                                    shaderCallback: (rect) => LinearGradient(
                                      colors: [tier.primaryColor, tier.secondaryColor],
                                    ).createShader(rect),
                                    child: Text(
                                      GameService.getRankTitle(info.level),
                                      style: AppText.headlineMd().copyWith(
                                        color: Colors.white,
                                        shadows: [Shadow(color: tier.primaryColor.withValues(alpha: 0.5), blurRadius: 12)],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            Text(
                              '$_nickname • Lv ${info.level}',
                              style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'XP PROGRESS',
                          style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AnimatedCount(
                        value: info.xpInCurrentLevel,
                        suffix: ' / ${info.xpNeededForNextLevel}',
                        style: AppText.bodyMd().copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  NeonProgressBar(progress: info.progress, leadingGlow: true, height: 10),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedCount(
                      value: info.xpNeededForNextLevel - info.xpInCurrentLevel,
                      suffix: ' XP TO NEXT RANK',
                      style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Satu strip HUD datar menggantikan 3 kartu (sholat aktif, next, streak).
  /// Cyan hanya untuk "sekarang", gold hanya untuk streak — disiplin warna.
  Widget _hudStrip() {
    final current = GameService.currentPrayerInfo(_state.timings);
    final np = GameService.nextPrayerInfo(_state.timings);
    final parts = np.split('|');
    final nextName = parts[0];
    final nextIn = parts.length > 2 ? parts[2] : '';

    Widget cell(String label, String value, String sub, Color valueColor) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.labelCapsSm()
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titleLg()
                    .copyWith(color: valueColor, fontSize: 16, height: 1.1)),
            const SizedBox(height: 2),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      );
    }

    Widget vDivider() => Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        );

    return FlatCard(
      child: Row(
        children: [
          cell(current.label.toUpperCase(), current.name,
              current.time, AppColors.tertiary),
          vDivider(),
          cell('BERIKUTNYA', nextName, nextIn, AppColors.onSurface),
          vDivider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STREAK',
                  style: AppText.labelCapsSm().copyWith(
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppColors.goldInk, size: 16),
                  const SizedBox(width: 2),
                  Text('${_state.heroStreak.current}',
                      style: AppText.titleLg().copyWith(
                          color: AppColors.goldInk,
                          fontSize: 16,
                          height: 1.1)),
                ],
              ),
              const SizedBox(height: 2),
              Text('hari',
                  style: AppText.bodyMd().copyWith(
                      color: AppColors.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ritualRings() {
    final wajib = GameService.checkedWajibToday;
    final sunnah = GameService.sunnahCountToday;
    final tilawah = GameService.tilawahDoneToday;
    final wProgress = (wajib / 5).clamp(0.0, 1.0);
    final sProgress = (sunnah / 8).clamp(0.0, 1.0);
    final tProgress = tilawah ? 1.0 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('RITUAL HARI INI'),
        FlatCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(painter: _RingsPainter(wProgress, sProgress, tProgress)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _ringStat('WAJIB', '$wajib/5', AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    _ringStat('SUNNAH', '$sunnah/8', AppColors.secondaryFixed),
                    const SizedBox(height: AppSpacing.sm),
                    _ringStat('TILAWAH', tilawah ? 'Lengkap' : 'Belum', AppColors.tertiary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ringStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
        const Spacer(),
        Text(value, style: AppText.bodyMd().copyWith(color: color)),
      ],
    );
  }

  Widget _prayerQuests() {
    final wajib = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];
    final done = GameService.checkedWajibToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('WAJIB QUEST',
            meta: '$done/5',
            accent: done == 5 ? AppColors.primary : null),
        ...wajib.map((p) {
          final done = GameService.isPrayerCheckedToday(p);
          final t = _state.timings;
          final active = !done && GameService.isCurrentOrUpcoming(p, t);
          final locked = !done && !GameService.isPrayerWindowOpen(p, t);
          final xp = const {'subuh': 30, 'dzuhur': 20, 'ashar': 20, 'maghrib': 25, 'isya': 25}[p] ?? 15;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _prayerRow(p, p.cap, done, active, locked, () => _togglePrayer(p, 'wajib'), xp),
          );
        }),
      ],
    );
  }

  /// ponytail: one pill, three callers — wajib/sunnah/tilawah share this.
  /// Flat tint (tanpa shadow) — kosakata RPG tetap, chrome hilang.
  Widget _xpPill(int xp, Color accent, Color onAccent,
      {bool done = false, bool locked = false}) {
    final muted = AppColors.onSurfaceVariant;
    final fg = locked ? muted.withValues(alpha: 0.7) : (done ? muted : accent);
    final bg = locked || done
        ? AppColors.surfaceContainerHigh.withValues(alpha: 0.6)
        : accent.withValues(alpha: 0.14);
    final label = locked ? 'LOCKED' : (done ? 'DONE' : '+$xp XP');
    final glyph = locked ? Icons.lock : (done ? Icons.check : Icons.bolt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(glyph, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(label, style: AppText.labelCaps().copyWith(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// ponytail: time-of-day glyph per wajib prayer — replaces generic check_circle.
  /// Color encodes state: done=primary, locked=grey, active=tertiary, else muted.
  IconData _prayerIcon(String key) => switch (key) {
        'subuh' => Icons.wb_twilight,    // fajar
        'dzuhur' => Icons.wb_sunny,      // terik
        'ashar' => Icons.wb_cloudy,      // sore
        'maghrib' => Icons.brightness_3, // senja (crescent)
        'isya' => Icons.nights_stay,     // malam
        _ => Icons.circle_outlined,
      };

  Widget _prayerRow(String key, String name, bool done, bool active, bool locked, VoidCallback onTap, int xp) {
    final dimmed = locked && !done;
    final iconColor = done
        ? AppColors.primary
        : (locked ? AppColors.onSurfaceVariant : (active ? AppColors.tertiary : AppColors.onSurfaceVariant));
    return PressableScale(
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            // Datar; hairline cyan HANYA di baris yang aktif sekarang —
            // satu-satunya sorotan dalam daftar.
            color: active
                ? AppColors.tertiary.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: active
                ? Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            children: [
              Icon(_prayerIcon(key), color: iconColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(name,
                    style: AppText.bodyMd().copyWith(
                      color: done
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                    )),
              ),
              _xpPill(xp, AppColors.primary, AppColors.onPrimary, done: done, locked: locked),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bonusQuest() {
    final t = _state.timings;
    final items = [
      ('Dhuha', 'dhuha', 'Sunnah mutlak di pagi hari', Icons.wb_sunny),
      ('Tahajjud', 'tahajjud', 'Sunnah malam (qiyamul lail)', Icons.nights_stay),
      ('Qobliyah Subuh', 'rawatib_subuh_qobliyah', 'Sunnah sebelum Subuh', Icons.history),
      ("Ba'diyah Subuh", 'rawatib_subuh_ba_diyyah', 'Sunnah sesudah Subuh', Icons.history),
      ('Qobliyah Dzuhur', 'rawatib_dzuhur_qobliyah', 'Sunnah sebelum Dzuhur', Icons.history),
      ("Ba'diyah Dzuhur", 'rawatib_dzuhur_ba_diyyah', 'Sunnah sesudah Dzuhur', Icons.history),
      ('Qobliyah Ashar', 'rawatib_ashar_qobliyah', 'Sunnah sebelum Ashar', Icons.history),
      ("Ba'diyah Maghrib", 'rawatib_maghrib_ba_diyyah', 'Sunnah sesudah Maghrib', Icons.history),
      ("Ba'diyah Isya", 'rawatib_isya_ba_diyyah', 'Sunnah sesudah Isya', Icons.history),
    ];
    final doneCount =
        items.where((it) => GameService.isPrayerCheckedToday(it.$2)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('BONUS QUEST · SUNNAH',
            meta: '$doneCount/${items.length}'),
        ...items.map((it) {
          final checked = GameService.isPrayerCheckedToday(it.$2);
          final onTime = GameService.isSunnahOnTime(it.$2, t);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _bonusRow(it.$1, it.$3, it.$4, AppColors.secondaryFixed,
                completed: checked, active: !checked && onTime, locked: !checked && !onTime,
                onTap: () => _togglePrayer(it.$2, 'sunnah')),
          );
        }),
      ],
    );
  }

  Widget _bonusRow(String name, String sub, IconData icon, Color color,
      {bool locked = false, bool completed = false, bool active = false, VoidCallback? onTap, int xp = 15}) {
    final dimmed = locked && !completed;
    final iconColor = completed
        ? color
        : (locked ? AppColors.onSurfaceVariant : (active ? color : AppColors.onSurfaceVariant));
    return PressableScale(
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: active
                ? Border.all(color: color.withValues(alpha: 0.45))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppText.bodyMd().copyWith(
                          color: completed
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        )),
                    Text(sub,
                        style: AppText.bodyMd().copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              _xpPill(xp, color, AppColors.onSecondary, done: completed, locked: locked),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questList() {
    final claimable =
        _state.quests.where((q) => q.completed && !q.claimed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('QUEST HARIAN',
            meta: claimable > 0 ? '$claimable SIAP KLAIM' : null,
            accent: claimable > 0 ? AppColors.primary : null),
        ..._state.quests.map((q) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _questCard(q),
            )),
      ],
    );
  }

  Widget _questCard(Quest q) {
    final claimable = q.completed && !q.claimed;
    final isClaiming = _claimingQuestId == q.id;
    return AnimatedScale(
      scale: isClaiming ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      child: PressableScale(
        onTap: claimable ? () => _claimQuest(q) : null,
        child: ShimmerSweep(
          enabled: claimable,
          radius: AppRadius.lg,
          color: AppColors.primary,
          child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: q.claimed
              ? AppColors.surfaceContainerLow.withValues(alpha: 0.5)
              : (claimable
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: claimable
              ? Border.all(
                  color: AppColors.primary
                      .withValues(alpha: isClaiming ? 0.9 : 0.45))
              : null,
        ),
          child: Row(
            children: [
              Icon(q.claimed ? Icons.check_circle : (q.completed ? Icons.card_giftcard : Icons.radio_button_unchecked),
                  color: q.claimed ? AppColors.onSurfaceVariant : AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.desc,
                        style: AppText.bodyMd().copyWith(
                            color: q.claimed ? AppColors.onSurfaceVariant : AppColors.onBackground,
                            decoration: q.claimed ? TextDecoration.lineThrough : null)),
                    Text('${q.progress}/${q.target} • +${q.xpReward} XP',
                        style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
                  ],
                ),
              ),
              if (claimable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text('CLAIM', style: AppText.labelCaps().copyWith(color: AppColors.onPrimary, fontSize: 10)),
                )
              else if (q.claimed)
                Icon(Icons.check, color: AppColors.onSurfaceVariant, size: 18),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _sideQuest(BuildContext context) {
    final sedekahDone = GameService.isPrayerCheckedToday('sedekah');
    final tilawahDone = GameService.tilawahDoneToday;
    const xp = 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('SIDE QUEST'),
        PressableScale(
          onTap: () => _togglePrayer('sedekah', 'sedekah'),
          child: FlatCard(
            child: Row(
              children: [
                Icon(Icons.favorite, color: AppColors.error, size: 26),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sedekah',
                          style: AppText.titleLg().copyWith(
                            fontSize: 16,
                            color: sedekahDone
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                          )),
                      Text(sedekahDone ? 'Selesai hari ini ✓' : 'Bersedekah hari ini',
                          style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                _xpPill(xp, AppColors.error, AppColors.onError, done: sedekahDone),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PressableScale(
          onTap: () => _togglePrayer('tilawah', 'tilawah'),
          child: FlatCard(
            child: Row(
              children: [
                Icon(Icons.menu_book, color: AppColors.tertiary, size: 26),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tilawah & Dzikir',
                          style: AppText.titleLg().copyWith(
                            fontSize: 16,
                            color: tilawahDone
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                          )),
                      Text(tilawahDone ? 'Selesai hari ini ✓' : 'Baca Al-Qur\'an / Dzikir',
                          style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                _xpPill(xp, AppColors.tertiary, AppColors.onTertiary, done: tilawahDone),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dailyBento() {
    final zikirCount = GameService.zikirCountToday;
    final goal = GameService.zikirGoal;
    final progress = (zikirCount / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('DAILY ZIKIR',
            meta: '$zikirCount/$goal',
            accent: zikirCount >= goal ? AppColors.primary : null),
        // ── Zikir tiles 2×2 — tinggi ngikutin konten (≈ tombol Daily Zikir),
        // bukan aspect ratio grid yang bikin tile ketinggian. IntrinsicHeight
        // menyamakan tinggi dua tile dalam satu baris (label bisa 2 baris).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _zikirTile('SUBHANALLAH', '33', AppColors.primary, '', Icons.refresh,
                    onTap: () => _showDzikir('Subhanallah',
                        'سُبْحَانَ اللَّهِ',
                        'Subhanallah',
                        'Maha Suci Allah, dzikir yang menumbuhkan pohon-pohon di surga.')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _zikirTile('ALHAMDULILLAH', '33', AppColors.tertiary, '', Icons.refresh,
                    onTap: () => _showDzikir('Alhamdulillah',
                        'الْحَمْدُ لِلَّهِ',
                        'Alhamdulillah',
                        'Segala puji bagi Allah, dzikir yang mengisi timbangan amal di hari kiamat.')),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _zikirTile('ALLAHU AKBAR', '33', AppColors.secondaryFixed, '', Icons.refresh,
                    onTap: () => _showDzikir('Allahu Akbar',
                        'اللَّهُ أَكْبَرُ',
                        'Allahu Akbar',
                        'Allah Maha Besar, dzikir yang membuka keberkahan dan ketenangan hati.')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _zikirTile('LA ILAHA ILLALLAH', '1', AppColors.tertiary, '', Icons.refresh,
                    onTap: () => _showDzikir('La ilaha illallah',
                        'لَا إِلَهَ إِلَّا اللَّهُ',
                        'La ilaha illallah',
                        'Tiada tuhan selain Allah, kalimat tauhid yang paling utama.')),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Zikir Clicker (full-width row below grid, no XP) ──
        PressableScale(
          pressedScale: 0.97,
          onTap: () async {
            final (newCount, _) = await GameService.incrementZikir();
            if (!mounted) return;
            setState(() {});
            if (newCount == goal) {
              _showZikirComplete();
              // Zikir 100 pertama → medali WOMBO COMBO.
              final newAch = await AchievementService.refresh();
              for (final a in newAch) {
                if (!mounted) break;
                await showAchievementUnlock(context, a);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              // Satu-satunya CTA di bagian bawah — tint primary tanpa border.
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TAP UNTUK ZIKIR', style: AppText.labelCaps().copyWith(color: AppColors.primary, fontSize: 10)),
                      const SizedBox(height: 4),
                      AnimatedCount(
                          value: zikirCount,
                          suffix: ' / $goal',
                          duration: const Duration(milliseconds: 350),
                          style: AppText.displayHero(28).copyWith(color: AppColors.primary)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.touch_app, color: AppColors.primary, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showZikirComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🎉 ', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Expanded(child: Text('Zikir harian selesai! MasyaAllah 🤲')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Daily Reward Chest ───
  Widget _dailyChest() {
    final wajibDone = GameService.checkedWajibToday;
    final isOpened = GameService.isDailyChestOpened;
    final isReady = GameService.isDailyChestAvailable;
    final totalWajib = 5;

    // Determine state
    final String emoji;
    final String label;
    final String subtitle;
    final Color accent;
    final bool canTap;

    if (isOpened) {
      emoji = '📭';
      label = 'CHEST DIBUKA';
      subtitle = 'Besok lagi ya kak! 🌙';
      accent = AppColors.onSurfaceVariant;
      canTap = false;
    } else if (isReady) {
      emoji = '🎁';
      label = 'REWARD SIAP!';
      subtitle = 'Klik untuk klaim 🎉';
      accent = AppColors.tertiary;
      canTap = true;
    } else {
      emoji = '🔒';
      label = 'DAILY CHEST';
      subtitle = 'Selesaikan 5 wajib';
      accent = AppColors.primary;
      canTap = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('DAILY CHEST',
            meta: isOpened ? 'DIBUKA' : '$wajibDone/$totalWajib WAJIB',
            accent: isReady ? AppColors.tertiary : null),
        PressableScale(
          onTap: canTap ? _claimChest : null,
          child: ShimmerSweep(
            enabled: isReady,
            color: AppColors.tertiary,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isReady
                    ? AppColors.tertiary.withValues(alpha: 0.08)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: isReady
                    ? Border.all(
                        color: AppColors.tertiary.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: AppText.labelCaps()
                                .copyWith(color: accent, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: AppText.bodyMd().copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 8),
                        // Progress dots: 5 wajib
                        Row(
                          children: List.generate(totalWajib, (i) {
                            final done = i < wajibDone;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done
                                      ? accent
                                      : accent.withValues(alpha: 0.2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  if (canTap)
                    Icon(Icons.arrow_forward_ios, color: accent, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _claimChest() async {
    final reveal = await GameService.claimDailyChest();
    if (!mounted || reveal == null) return;
    setState(() {});
    _showChestReveal(reveal);
  }

  void _showChestReveal(ChestRevealState reveal) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.tertiary.withValues(alpha: 0.2),
                  AppColors.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: AppColors.tertiary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji reward
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiary.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(reveal.rewardEmoji, style: const TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('REWARD DIDAPAT!',
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.tertiary,
                      fontSize: 12,
                    )),
                const SizedBox(height: AppSpacing.sm),
                Text(reveal.rewardName,
                    style: AppText.displayHero(20).copyWith(
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                // XP reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text('+${reveal.xpReward} XP',
                      style: AppText.labelCaps().copyWith(
                        color: AppColors.tertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                ),
                if (reveal.isDuplicate) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Item duplikat — koleksi tetap tersimpan 📦',
                      style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      )),
                ],
                if (reveal.levelsGained > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('⬆️ Level Up!${reveal.levelsGained > 1 ? ' x${reveal.levelsGained}' : ''}',
                      style: AppText.labelCaps().copyWith(
                        color: AppColors.tertiary,
                        fontSize: 14,
                      )),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Alhamdulillah! 🤲'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _zikirTile(String label, String count, Color color, String cta, IconData icon, {VoidCallback? onTap}) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppText.labelCaps().copyWith(color: color, fontSize: 10)),
            const SizedBox(height: 4),
            Text(count, style: AppText.displayHero(32).copyWith(color: color)),
            if (cta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 12),
                  const SizedBox(width: 4),
                  Text(cta, style: AppText.labelCaps().copyWith(color: color, fontSize: 10)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDzikir(String title, String arabic, String translit, String meaning) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppText.headlineLg().copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.md),
              Text(arabic,
                  style: AppText.headlineMd().copyWith(color: AppColors.onSurface, height: 1.6),
                  textAlign: TextAlign.right),
              const SizedBox(height: AppSpacing.sm),
              Text(translit,
                  style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
              const SizedBox(height: AppSpacing.sm),
              Text(meaning, style: AppText.bodyMd().copyWith(color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double wajib, sunnah, tilawah;
  _RingsPainter(this.wajib, this.sunnah, this.tilawah);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [56.0, 42.0, 28.0];
    final colors = [AppColors.primary, AppColors.secondaryFixed, AppColors.tertiary];
    final progresses = [wajib, sunnah, tilawah];

    for (var i = 0; i < radii.length; i++) {
      final paintBg = Paint()
        ..color = AppColors.surfaceContainerHighest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radii[i], paintBg);

      if (progresses[i] > 0) {
        final paintFg = Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
        final sweep = 2 * 3.14159 * progresses[i];
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radii[i]),
          -3.14159 / 2,
          sweep,
          false,
          paintFg,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.wajib != wajib || old.sunnah != sunnah || old.tilawah != tilawah;
}

/// Faint 8-pointed star lattice (khatam pattern) for the hero rank card.
class _GeoPatternPainter extends CustomPainter {
  final Color color;
  _GeoPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const cell = 44.0;
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), cell * 0.36, paint);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final radius = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + radius * math.cos(angle), c.dy + radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GeoPatternPainter old) => old.color != color;
}
