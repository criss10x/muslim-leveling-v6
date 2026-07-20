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
  }

  @override
  void dispose() {
    _tick?.cancel();
    PrayerService.locationVersion.removeListener(_onLocationChanged);
    super.dispose();
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
      content: Text(msg, style: AppText.bodyMd().copyWith(color: Colors.white)),
      backgroundColor: AppColors.surfaceContainerHigh,
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
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.onSurfaceVariant),
          onPressed: widget.onSettingsPressed,
        ),
      ],
    );
  }

  Widget _heroRank(LevelInfo info) {
    final tier = getTierVisualConfig(getTierName(info.level));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: tier.primaryColor.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tier.primaryColor.withValues(alpha: 0.14),
                AppColors.surfaceContainer.withValues(alpha: 0.75),
                tier.secondaryColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: tier.primaryColor.withValues(alpha: 0.45), width: 1.5),
          ),
          child: Stack(
            children: [
              // subtle Islamic geometric lattice, tinted by tier
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GeoPatternPainter(tier.primaryColor)),
                ),
              ),
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tier.primaryColor.withValues(alpha: 0.10),
                    boxShadow: [BoxShadow(color: tier.secondaryColor.withValues(alpha: 0.12), blurRadius: 60)],
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
                            ShaderMask(
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
                style: AppText.labelCaps()
                    .copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
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
                  style: AppText.labelCaps().copyWith(
                      color: AppColors.onSurfaceVariant, fontSize: 9)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.secondaryFixed, size: 16),
                  const SizedBox(width: 2),
                  Text('${_state.heroStreak.current}',
                      style: AppText.titleLg().copyWith(
                          color: AppColors.secondaryFixed,
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
