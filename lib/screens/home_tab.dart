import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/game_service.dart';
import '../../services/prayer_service.dart';
import 'naik_level_screen.dart';

extension _StringExt on String {
  String get cap => '${this[0].toUpperCase()}${substring(1)}';
}

/// Home / Dashboard Utama — live game logic (port V3), design preserved.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
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
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    _error = '';
    try {
      await GameService.load();
      await GameService.ensureDailyQuests();
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
      if (GameService.current.timings.subuh != '04:42') return;
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
      }
    } catch (_) {
      // ponytail: timings are optional; never let this block home
    }
  }

  Future<void> _togglePrayer(String prayer, String type) async {
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
    final (_, xp, levelUp) = res;
    _toast('+$xp XP!${levelUp ? " 🎉 LEVEL UP!" : ""}');
    if (levelUp && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NaikLevelScreen(xpGained: xp)));
    }
  }

  Future<void> _claimQuest(Quest q) async {
    if (!q.completed || q.claimed || _claimingQuestId.isNotEmpty) return;
    setState(() => _claimingQuestId = q.id);
    final (s, didLevelUp) = await GameService.claimQuest(q.id);
    if (!mounted) return;
    setState(() {
      _state = s;
      _claimingQuestId = '';
    });
    _toast('+${q.xpReward} XP dari quest!');
    if (didLevelUp && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NaikLevelScreen(xpGained: q.xpReward)));
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppText.bodyMd().copyWith(color: Colors.white)),
      backgroundColor: AppColors.surfaceContainerHigh,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final info = GameService.getLevelInfo(_state.xp);
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _load(showLoading: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 100),
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _appBar(context)),
              const SizedBox(height: AppSpacing.md),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _heroRank(info)),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _countdownCard()),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _streakCard()),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _ritualRings()),
              const SizedBox(height: AppSpacing.lg),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _prayerQuests()),
              const SizedBox(height: AppSpacing.lg),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _bonusQuest()),
              const SizedBox(height: AppSpacing.lg),
              if (_state.quests.isNotEmpty)
                Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _questList()),
              if (_state.quests.isNotEmpty) const SizedBox(height: AppSpacing.lg),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _sideQuest(context)),
              const SizedBox(height: AppSpacing.lg),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: _dailyBento()),
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

  Widget _appBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainer,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.shield, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [AppColors.primary, AppColors.tertiary],
          ).createShader(rect),
          child: Text(
            'MUSLIM LEVELING',
            style: AppText.headlineMd().copyWith(color: Colors.white, fontSize: 18, height: 1.0),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings, color: AppColors.primary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _heroRank(LevelInfo info) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 60)],
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
                        Text(
                          GameService.getRankTitle(info.level),
                          style: AppText.headlineMd().copyWith(
                            color: AppColors.primary,
                            shadows: [Shadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12)],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$_nickname • Lv ${info.level}',
                          style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: AppColors.secondaryContainer),
                        const SizedBox(width: 4),
                        Text('${_state.heroStreak.current} Hari', style: AppText.labelCaps()),
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
                  Flexible(
                    child: Text(
                      '${info.xpInCurrentLevel} / ${info.xpNeededForNextLevel}',
                      style: AppText.bodyMd().copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              NeonProgressBar(progress: info.progress),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${info.xpNeededForNextLevel - info.xpInCurrentLevel} XP to Next Rank',
                  style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownCard() {
    final np = GameService.nextPrayerInfo(_state.timings);
    final parts = np.split('|');
    final name = parts[0];
    final time = parts.length > 1 ? parts[1] : '--:--';
    final countdown = parts.length > 2 ? parts[2] : '';
    return NeonPulse(
      color: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NEXT MATCH', style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
            const SizedBox(height: AppSpacing.xs),
            Text(name.toUpperCase(), style: AppText.headlineMd().copyWith(color: AppColors.tertiary)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: AppColors.onBackground, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(countdown, style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _streakCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainer.withValues(alpha: 0.8),
            AppColors.surfaceContainer.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppColors.secondaryFixed.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryFixed.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: AppColors.secondaryFixed.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: const Icon(Icons.local_fire_department, color: AppColors.secondaryFixed, size: 28),
          ),
          const SizedBox(height: 8),
          Text('${_state.heroStreak.current}', style: AppText.displayHero(28).copyWith(color: AppColors.secondaryFixed, height: 1.0)),
          const SizedBox(height: 2),
          Text('HARI STREAK',
              textAlign: TextAlign.center,
              style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
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
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text('RITUAL RINGS', style: AppText.labelCaps().copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
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
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag, color: AppColors.primary, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text('WAJIB QUEST', style: AppText.labelCaps().copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...wajib.map((p) {
          final done = GameService.isPrayerCheckedToday(p);
          final t = _state.timings;
          final active = !done && GameService.isCurrentOrUpcoming(p, t);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _prayerRow(p.cap, done, active, () => _togglePrayer(p, 'wajib')),
          );
        }),
      ],
    );
  }

  Widget _prayerRow(String name, bool done, bool active, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: done
              ? AppColors.primary.withValues(alpha: 0.6)
              : (active ? AppColors.tertiary.withValues(alpha: 0.6) : AppColors.outlineVariant.withValues(alpha: 0.2)),
          width: done || active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : (active ? Icons.circle_outlined : Icons.radio_button_unchecked),
                color: done ? AppColors.primary : (active ? AppColors.tertiary : AppColors.onSurfaceVariant), size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(name, style: AppText.bodyMd())),
            if (done)
              Text('SELESAI', style: AppText.labelCaps().copyWith(color: AppColors.primary, fontSize: 10))
            else if (active)
              Text('AKTIF', style: AppText.labelCaps().copyWith(color: AppColors.tertiary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _bonusQuest() {
    final t = _state.timings;
    final items = [
      ('Dhuha', 'dhuha', 'Setelah matahari naik sampai sebelum Dzuhur', Icons.wb_sunny),
      ('Tahajjud', 'tahajjud', 'Setelah Isya sampai sebelum Imsak', Icons.nights_stay),
      ('Qobliyah Subuh', 'rawatib_subuh_qobliyah', '2 rakaat sebelum Subuh', Icons.history),
      ("Ba'diyah Subuh", 'rawatib_subuh_ba_diyyah', '2 rakaat sesudah Subuh', Icons.history),
      ('Qobliyah Dzuhur', 'rawatib_dzuhur_qobliyah', '2-4 rakaat sebelum Dzuhur', Icons.history),
      ("Ba'diyah Dzuhur", 'rawatib_dzuhur_ba_diyyah', '2 rakaat sesudah Dzuhur', Icons.history),
      ('Qobliyah Ashar', 'rawatib_ashar_qobliyah', '2-4 rakaat sebelum Ashar', Icons.history),
      ("Ba'diyah Maghrib", 'rawatib_maghrib_ba_diyyah', '2 rakaat sesudah Maghrib', Icons.history),
      ("Ba'diyah Isya", 'rawatib_isya_ba_diyyah', '2 rakaat sesudah Isya', Icons.history),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars, color: AppColors.secondaryFixed, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text('BONUS QUEST — SUNNAH', style: AppText.labelCaps().copyWith(color: AppColors.secondaryFixed)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...items.map((it) {
          final checked = GameService.isPrayerCheckedToday(it.$2);
          final onTime = GameService.isSunnahOnTime(it.$2, t);
          final locked = !checked && !onTime;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _bonusRow(it.$1, it.$3, it.$4, AppColors.secondaryFixed,
                completed: checked, locked: locked, onTap: () => _togglePrayer(it.$2, 'sunnah')),
          );
        }),
      ],
    );
  }

  Widget _bonusRow(String name, String sub, IconData icon, Color color,
      {bool locked = false, bool completed = false, VoidCallback? onTap}) {
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: InkWell(
          onTap: locked ? null : onTap,
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.bodyLg()),
                    Text('Bonus XP', style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
                  ],
                ),
              ),
              Icon(
                completed
                    ? Icons.check_circle
                    : locked
                        ? Icons.lock_clock
                        : Icons.radio_button_unchecked,
                color: completed ? AppColors.primary : (locked ? AppColors.outline : color),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.military_tech, color: AppColors.primary, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text('QUEST HARIAN', style: AppText.labelCaps().copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: q.claimed
              ? AppColors.surfaceContainer.withValues(alpha: 0.3)
              : (claimable ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceContainer.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isClaiming
                ? AppColors.primary
                : (claimable ? AppColors.primary.withValues(alpha: 0.6) : AppColors.outlineVariant.withValues(alpha: 0.2)),
            width: isClaiming ? 2 : 1,
          ),
          boxShadow: isClaiming
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: InkWell(
          onTap: claimable ? () => _claimQuest(q) : null,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('CLAIM', style: AppText.labelCaps().copyWith(color: AppColors.onPrimary, fontSize: 10)),
                )
              else if (q.claimed)
                const Icon(Icons.check, color: AppColors.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideQuest(BuildContext context) {
    final done = GameService.tilawahDoneToday;
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('📜 SIDE QUEST', style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant)),
            ),
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.tertiary.withValues(alpha: 0.2),
              AppColors.primary.withValues(alpha: 0.1),
            ]),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.15), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: InkWell(
            onTap: () => _togglePrayer('tilawah', 'tilawah'),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.menu_book, color: AppColors.tertiary, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tilawah & Dzikir', style: AppText.headlineMd().copyWith(fontSize: 18)),
                      Text(done ? 'Selesai hari ini ✓' : 'Baca Al-Qur\'an / Dzikir',
                          style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: done ? AppColors.onSurfaceVariant : AppColors.tertiary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.6), blurRadius: 12)],
                  ),
                  child: Icon(done ? Icons.check : Icons.play_arrow, color: AppColors.onTertiary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dailyBento() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 0.95,
      children: [
        _zikirTile('SUBHANALLAH', '33', AppColors.primary, '+1 XP', Icons.refresh),
        _zikirTile('ALHAMDULILLAH', '33', AppColors.tertiary, '+1 XP', Icons.refresh),
        _zikirTile('ALLAHU AKBAR', '34', AppColors.secondaryFixed, '+1 XP', Icons.refresh),
        _zikirTile('DZIKIR PAGI', '5/8', AppColors.primary, 'MENU', Icons.arrow_forward),
      ],
    );
  }

  Widget _zikirTile(String label, String count, Color color, String cta, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppText.labelCaps().copyWith(color: color, fontSize: 10)),
          const SizedBox(height: 4),
          Text(count, style: AppText.displayHero(32).copyWith(color: color)),
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
        final sweep = 2 * 3.14159 * (1 - progresses[i]);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radii[i]),
          -3.14159 / 2,
          2 * 3.14159 - sweep,
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
