import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/city_picker.dart';
import '../../services/prayer_service.dart';
import '../../services/game_service.dart';
import 'qibla_screen.dart';

/// Jadwal Sholat — V3 logic ported to V1 design.
/// Shows next prayer countdown, 5 daily prayers with logged status,
/// and info card about data source.
class JadwalTab extends StatefulWidget {
  const JadwalTab({super.key});

  @override
  State<JadwalTab> createState() => _JadwalTabState();
}

class _JadwalTabState extends State<JadwalTab> {
  Map<String, String>? _jadwal;
  String _cityName = 'Jakarta';
  String _cityId = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
    // Refetch saat kota diganti dari tab lain (profil/onboarding).
    PrayerService.locationVersion.addListener(_loadAndFetch);
    // Rebuild status "sudah dilog" saat sholat dicentang di tab Home.
    GameService.stateVersion.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    PrayerService.locationVersion.removeListener(_loadAndFetch);
    GameService.stateVersion.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAndFetch() async {
    final loc = await PrayerService.loadLocation();
    if (loc == null) {
      // Jangan fetch dengan ID default — API v3 pakai MD5 city ID,
      // ID numerik lama tidak valid. Onboarding harusnya sudah menyimpan
      // lokasi; ini pengaman kalau prefs kosong.
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Belum ada lokasi tersimpan. Tap ikon lokasi untuk pilih kota.';
        });
      }
      return;
    }
    _cityId = loc.id;
    _cityName = loc.name;
    await _fetch();
  }

  Future<void> _changeLocation() async {
    final picked = await CityPicker.show(context);
    if (picked == null) return;
    // saveLocation membump locationVersion → _loadAndFetch jalan via listener
    // (sekalian home_tab ikut refresh timing + reschedule notif adzan).
    await PrayerService.saveLocation(picked.id, picked.name);
  }

  Future<void> _fetch() async {
    if (_cityId.isEmpty) return _loadAndFetch();
    setState(() {
      _loading = true;
      _error = null;
    });
    final j = await PrayerService.fetchSchedule(cityId: _cityId);
    if (!mounted) return;
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
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Compute next prayer name, time, and countdown (port V3 logic).
  ({String name, String time, String countdown}) _nextPrayer() {
    final j = _jadwal;
    if (j == null || _loading) {
      return (name: '—', time: '--:--', countdown: 'memuat...');
    }

    final now = TimeOfDay.now();
    final prayers = [
      ('Subuh', j['subuh'] ?? ''),
      ('Dzuhur', j['dzuhur'] ?? ''),
      ('Ashar', j['ashar'] ?? ''),
      ('Maghrib', j['maghrib'] ?? ''),
      ('Isya', j['isya'] ?? ''),
    ];

    final minsNow = now.hour * 60 + now.minute;

    for (final p in prayers) {
      if (p.$2.isEmpty) continue;
      final parts = p.$2.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final minsP = h * 60 + m;
      if (minsP > minsNow) {
        final diff = minsP - minsNow;
        final hh = diff ~/ 60;
        final mm = diff % 60;
        final countdown = hh > 0 ? '${hh}j ${mm}m lagi' : '${mm}m lagi';
        return (name: p.$1, time: p.$2, countdown: countdown);
      }
    }

    // All passed → Subuh tomorrow
    return (name: 'Subuh', time: j['subuh'] ?? '04:42', countdown: 'besok');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const SizedBox(height: AppSpacing.lg),
              _header(),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _nextPrayerCard(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _qiblaButton(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _schedule(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _infoCard(),
              ),
            ],
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
          Text('Waktu Sholat', style: AppText.displayHero(32)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(_todayLabel(), style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('•', style: TextStyle(color: AppColors.outlineVariant)),
              ),
              const Icon(Icons.location_on, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: _changeLocation,
                  child: Text(
                    _cityName,
                    style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              InkWell(
                onTap: _changeLocation,
                child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qiblaButton() {
    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QiblaScreen(cityName: _cityName),
          ),
        );
      },
      // Tint gold tenang — kiblat = item spesial tab ini, tapi bukan hero.
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore, size: 22, color: AppColors.secondaryFixed),
            const SizedBox(width: AppSpacing.sm),
            Text('Kompas Kiblat',
                style: AppText.titleLg()
                    .copyWith(fontSize: 15, color: AppColors.onSurface)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.secondaryFixed),
          ],
        ),
      ),
    );
  }

  Widget _nextPrayerCard() {
    final next = _nextPrayer();

    // Hero tab ini — satu-satunya elemen dengan foto + glow (statis,
    // konsisten dengan hero Status Window di Home).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Container(
          color: AppColors.surfaceContainerHigh,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/mosque_bg.jpg', fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.7)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
                                      Text('SHOLAT BERIKUTNYA', style: AppText.labelCaps().copyWith(color: AppColors.primary)),
                                      const SizedBox(height: 2),
                                      Text(next.name, style: AppText.headlineLg()),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer, size: 14, color: AppColors.secondaryFixed),
                                        const SizedBox(width: 4),
                                        Text(next.countdown, style: AppText.labelCaps().copyWith(color: AppColors.secondaryFixed)),
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
                                      next.time,
                                      style: AppText.displayHero(40).copyWith(color: Colors.white),
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.5)),
                                    ),
                                    child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _schedule() {
    final j = _jadwal;
    final now = TimeOfDay.now();
    final next = _nextPrayer();
    final minsNow = now.hour * 60 + now.minute;

    ({String name, String id, String time, IconData icon, bool isNext, bool isLogged}) row(
      String name,
      String id,
      String time,
      IconData icon,
    ) {
      if (time.isEmpty) return (name: name, id: id, time: '--:--', icon: icon, isNext: false, isLogged: false);
      final parts = time.split(':');
      if (parts.length != 2) return (name: name, id: id, time: time, icon: icon, isNext: false, isLogged: false);
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final mins = h * 60 + m;
      final isNext = name == next.name && mins > minsNow;
      final isLogged = GameService.isPrayerCheckedToday(id);
      return (name: name, id: id, time: time, icon: icon, isNext: isNext, isLogged: isLogged);
    }

    final items = [
      row('Subuh', 'subuh', j?['subuh'] ?? '', Icons.wb_twilight),
      row('Dzuhur', 'dzuhur', j?['dzuhur'] ?? '', Icons.wb_sunny),
      row('Ashar', 'ashar', j?['ashar'] ?? '', Icons.wb_cloudy),
      row('Maghrib', 'maghrib', j?['maghrib'] ?? '', Icons.wb_twilight),
      row('Isya', 'isya', j?['isya'] ?? '', Icons.nightlight),
    ];

    final logged = items.where((it) => it.isLogged).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('5 WAKTU SHOLAT',
            meta: '$logged/5',
            accent: logged == 5 ? AppColors.primary : null),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _scheduleRow(it.name, it.time, it.icon, it.isNext, it.isLogged),
            )),
      ],
    );
  }

  Widget _scheduleRow(String name, String time, IconData icon, bool isNext, bool isLogged) {
    // Disiplin warna redesign: cyan = berikutnya/sekarang, primary = selesai.
    final iconColor = isNext
        ? AppColors.tertiary
        : isLogged
            ? AppColors.primary
            : AppColors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.tertiary.withValues(alpha: 0.06)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: isNext
            ? Border.all(color: AppColors.tertiary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.titleLg().copyWith(
                    fontSize: 16,
                    color: isLogged
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                  ),
                ),
                if (isNext)
                  Text(
                    'BERIKUTNYA',
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.tertiary,
                      fontSize: 9,
                    ),
                  )
                else if (isLogged)
                  Text(
                    '✓ SUDAH DILOG',
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.primary.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNext ? AppColors.tertiary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    // Footnote tenang, bukan kartu — sumber data cukup sekali dibaca.
    return Text(
      'Jadwal dari data KEMENAG RI via api.myquran.com untuk $_cityName. '
      'Ter-update otomatis saat tab dibuka; tap nama kota di atas untuk ganti lokasi.',
      style: AppText.bodyMd().copyWith(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: 11,
        height: 1.5,
      ),
    );
  }
}
