import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/prayer_service.dart';

/// Jadwal Sholat — hero icons edition. Next prayer + daily schedule list.
/// Live data from api.myquran.com (Kemenag proxy).
class JadwalTab extends StatefulWidget {
  const JadwalTab({super.key});

  @override
  State<JadwalTab> createState() => _JadwalTabState();
}

class _JadwalTabState extends State<JadwalTab> {
  Map<String, String>? _jadwal;
  String _cityName = 'Jakarta';
  String _cityId = '1301';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final loc = await PrayerService.loadLocation();
    if (loc != null) {
      _cityId = loc.id;
      _cityName = loc.name;
    } else {
      // ponytail: default Jakarta. User can change via Profil.
      final p = await SharedPreferences.getInstance();
      await p.setString('city_id', _cityId);
      await p.setString('city_name', _cityName);
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final j = await PrayerService.fetchSchedule(cityId: _cityId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _jadwal = j;
      if (j == null) {
        _error = 'Gagal memuat jadwal. Periksa koneksi.';
      } else if (j['lokasi']?.isNotEmpty == true) {
        _cityName = j['lokasi']!;
      }
    });
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const SizedBox(height: AppSpacing.md),
              _pill(),
              const SizedBox(height: AppSpacing.xs),
              _header(),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _qiblaButton(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _nextPrayerCard(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _schedule(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _monthlyTracker(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondaryContainer.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'JADWAL SHOLAT',
          style: AppText.labelCaps().copyWith(
            color: AppColors.secondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.onSurface, size: 32),
              const SizedBox(width: 4),
              Text('Waktu Sholat', style: AppText.displayHero(32)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _todayLabel(),
                style: AppText.bodyMd().copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('•', style: TextStyle(color: AppColors.outlineVariant)),
              ),
              const Icon(Icons.location_on, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _cityName,
                  style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
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

  Widget _qiblaButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondaryContainer, AppColors.secondaryFixed],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl - 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore, size: 24, color: AppColors.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Kompas Kiblat',
              style: AppText.titleLg().copyWith(
                color: AppColors.onSecondaryContainer,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: AppColors.onSecondaryContainer),
          ],
        ),
      ),
    );
  }

  Widget _nextPrayerCard() {
    // Compute next prayer from live data
    final j = _jadwal;
    String nextName = 'Ashar';
    String nextTime = '15:12';
    String countdown = 'memuat...';

    if (j != null && !_loading) {
      final now = TimeOfDay.now();
      final prayers = [
        ('Subuh', j['subuh'] ?? ''),
        ('Dzuhur', j['dzuhur'] ?? ''),
        ('Ashar', j['ashar'] ?? ''),
        ('Maghrib', j['maghrib'] ?? ''),
        ('Isya', j['isya'] ?? ''),
      ];
      String? found;
      for (final p in prayers) {
        if (p.$2.isEmpty) continue;
        final parts = p.$2.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final t = TimeOfDay(hour: h, minute: m);
        final minsNow = now.hour * 60 + now.minute;
        final minsP = t.hour * 60 + t.minute;
        if (minsP > minsNow) {
          found = '${p.$1}|${p.$2}|${minsP - minsNow}';
          break;
        }
      }
      if (found != null) {
        final sp = found.split('|');
        nextName = sp[0];
        nextTime = sp[1];
        final diff = int.tryParse(sp[2]) ?? 0;
        final hh = diff ~/ 60;
        final mm = diff % 60;
        countdown = hh > 0 ? '${hh}j ${mm}m lagi' : '${mm}m lagi';
      } else {
        // All prayers passed — next is Subuh tomorrow
        nextName = 'Subuh';
        nextTime = j['subuh'] ?? '04:32';
        countdown = 'besok';
      }
    }

    return NeonPulse(
      color: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off, color: AppColors.error, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _fetch,
                            child: Text('Coba lagi', style: AppText.bodyMd().copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELANJUTNYA',
                                style: AppText.labelCaps().copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(nextName, style: AppText.headlineLg()),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBright.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: AppColors.secondaryFixed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  countdown,
                                  style: AppText.labelCaps().copyWith(
                                    color: AppColors.secondaryFixed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryFixed],
                            ).createShader(rect),
                            child: Text(
                              nextTime,
                              style: AppText.displayHero(40).copyWith(color: Colors.white),
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _schedule() {
    final j = _jadwal;
    final now = TimeOfDay.now();

    (String, String, IconData, bool, bool) row(String name, String time, IconData icon) {
      if (time.isEmpty) return (name, '--:--', icon, false, false);
      final parts = time.split(':');
      if (parts.length != 2) return (name, time, icon, false, false);
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final mins = h * 60 + m;
      final minsNow = now.hour * 60 + now.minute;
      final completed = mins < minsNow;
      final active = !completed &&
          (mins - minsNow) <= 30; // active if within next 30 min
      return (name, time, icon, completed, active);
    }

    final items = [
      row('Subuh', j?['subuh'] ?? '', Icons.wb_twilight),
      row('Dzuhur', j?['dzuhur'] ?? '', Icons.wb_sunny),
      row('Ashar', j?['ashar'] ?? '', Icons.wb_cloudy),
      row('Maghrib', j?['maghrib'] ?? '', Icons.wb_twilight),
      row('Isya', j?['isya'] ?? '', Icons.nightlight),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JADWAL HARI INI',
          style: AppText.labelCaps().copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _scheduleRow(it.$1, it.$2, it.$3, it.$4, it.$5),
            )),
      ],
    );
  }

  Widget _scheduleRow(
    String name,
    String time,
    IconData icon,
    bool completed,
    bool active,
  ) {
    final color = active
        ? AppColors.primary
        : (completed ? AppColors.onSurfaceVariant : AppColors.onSurface);
    return Opacity(
      opacity: completed ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: active
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              name,
              style: AppText.titleLg().copyWith(
                color: color,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (completed) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthlyTracker() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STREAK BULANAN',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(28, (i) {
              final filled = i < 12;
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '12/28 hari istiqomah',
            style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
