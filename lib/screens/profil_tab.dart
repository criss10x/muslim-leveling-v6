import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/prayer_service.dart';
import '../../services/game_service.dart';
import 'statistik_sheet.dart';


/// Profil Pejuang — hero header, stats grid, achievements, settings rows.
class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  String _nickname = 'Pejuang';
  String _cityName = 'Jakarta';
  // ponytail: cityId kept for future "show on map" feature
  // ignore: unused_field
  String _cityId = '1301';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await GameService.load();
    final p = await SharedPreferences.getInstance();
    final loc = await PrayerService.loadLocation();
    setState(() {
      _nickname = p.getString('nickname') ?? 'Pejuang';
      _avatarPath = p.getString('avatar_path');
      if (loc != null) {
        _cityId = loc.id;
        _cityName = loc.name;
      }
    });
  }

  Future<void> _refresh() async {
    await _loadProfile();
  }

  Future<void> _editNickname() async {
    final ctrl = TextEditingController(text: _nickname);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Edit Nama', style: AppText.titleLg()),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppText.bodyLg(),
          decoration: InputDecoration(
            hintText: 'Nama panggilan',
            hintStyle: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Simpan', style: AppText.bodyMd().copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('nickname', result);
    setState(() => _nickname = result);
  }

  Future<void> _editLocation() async {
    final ctrl = TextEditingController();
    List<Map<String, dynamic>> results = const [];
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> search(String q) async {
            if (q.trim().length < 3) {
              setState(() => results = const []);
              return;
            }
            setState(() => loading = true);
            final r = await PrayerService.searchCities(q);
            setState(() {
              results = r;
              loading = false;
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerHigh,
            title: Text('Pilih Lokasi', style: AppText.titleLg()),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: AppText.bodyLg(),
                    decoration: InputDecoration(
                      hintText: 'Ketik nama kota/kab...',
                      hintStyle: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: search,
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  else if (results.isEmpty && ctrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Kota tidak ditemukan',
                        style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final c = results[i];
                          final name = c['lokasi'] as String? ?? '';
                          final id = c['id']?.toString() ?? '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                            title: Text(name, style: AppText.bodyMd()),
                            onTap: () async {
                              await PrayerService.saveLocation(id, name);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              setState2() {
                                this.setState(() {
                                  _cityId = id;
                                  _cityName = name;
                                });
                              }
                              setState2();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/avatar.jpg');
    await file.writeAsBytes(bytes);
    final p = await SharedPreferences.getInstance();
    await p.setString('avatar_path', file.path);
    setState(() => _avatarPath = file.path);
  }

  Future<void> _removeAvatar() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('avatar_path');
    if (_avatarPath != null) {
      try {
        await File(_avatarPath!).delete();
      } catch (_) {}
    }
    setState(() => _avatarPath = null);
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Ganti Foto', style: AppText.bodyLg()),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar();
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: Text('Hapus Foto', style: AppText.bodyLg().copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(top: AppSpacing.md, bottom: 100),
            children: [
              _hero(context),
              const SizedBox(height: AppSpacing.lg),
              _stats(),
              const SizedBox(height: AppSpacing.md),
              _prayerStreaks(),
              const SizedBox(height: AppSpacing.md),
              HeroButton(
                label: 'Lihat Statistik',
                trailingIcon: Icons.bar_chart,
                onPressed: () => StatistikSheet.show(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _badges(),
              const SizedBox(height: AppSpacing.lg),
              _settings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
              children: [
                GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.secondaryContainer, AppColors.secondaryFixed],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryFixed.withValues(alpha: 0.4),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: _avatarPath != null && File(_avatarPath!).existsSync()
                              ? Image.file(
                                  File(_avatarPath!),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.shield,
                                  color: AppColors.onSecondaryContainer,
                                  size: 32,
                                ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: AppColors.onPrimary, size: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nickname,
                        style: AppText.headlineMd().copyWith(fontSize: 20),
                      ),
                      Text(
                        GameService.getRankTitle(GameService.current.level),
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: _editNickname,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          // Location row — editable
          InkWell(
            onTap: _editLocation,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOKASI',
                          style: AppText.labelCaps().copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _cityName,
                          style: AppText.bodyLg().copyWith(color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Level', '${GameService.current.level}'),
              _miniStat('XP', '${GameService.current.xp}'),
              _miniStat('Streak', '${GameService.current.heroStreak.current}🔥'),
              _miniStat('Rank', GameService.getRankTitle(GameService.current.level)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppText.titleLg().copyWith(color: AppColors.primary),
          ),
        ),
        Text(
          label,
          style: AppText.labelCaps().copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _stats() {
    final logs = GameService.current.prayerLog;
    final wajibTotal = logs.where((l) => GameService.wajibList.contains(l.prayer)).length;
    final sunnahTotal = logs.where((l) => l.type == 'sunnah' || l.prayer.startsWith('rawatib')).length;
    final tilawahTotal = logs.where((l) => l.prayer == 'tilawah').length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: [
        _statCard('Sholat Selesai', '$wajibTotal', 'total', Icons.mosque, AppColors.primary),
        _statCard('Tilawah', '$tilawahTotal', 'kali', Icons.menu_book, AppColors.tertiary),
        _statCard('Sunnah', '$sunnahTotal', 'total', Icons.volunteer_activism, AppColors.secondaryFixed),
        _statCard('Hero Streak', '${GameService.current.heroStreak.current}', 'hari', Icons.local_fire_department, AppColors.tertiaryContainer),
      ],
    );
  }

  Widget _statCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppText.labelCaps().copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppText.titleLg().copyWith(color: color, fontSize: 20),
          ),
          Text(
            sub,
            style: AppText.bodyMd().copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prayerStreaks() {
    final prayers = [
      ('Subuh', 'subuh'),
      ('Dzuhur', 'dzuhur'),
      ('Ashar', 'ashar'),
      ('Maghrib', 'maghrib'),
      ('Isya', 'isya'),
    ];
    final streaks = GameService.current.perPrayerStreaks;

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streak per Sholat',
            style: AppText.titleLg().copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: prayers.map((p) {
                final label = p.$1;
                final key = p.$2;
                final count = streaks[key]?.current ?? 0;
                final active = count > 0;
                return Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerLow.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: active
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AppText.bodyMd().copyWith(
                          color: active
                              ? AppColors.primaryFixed
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: active ? AppColors.secondaryFixed : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$count',
                            style: AppText.bodyLg().copyWith(
                              color: active ? AppColors.onSurface : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badges() {
    final logs = GameService.current.prayerLog;
    final hero = GameService.current.heroStreak;
    final subuhStreak = GameService.current.perPrayerStreaks['subuh']?.current ?? 0;
    final wajibTotal = logs.where((l) => GameService.wajibList.contains(l.prayer)).length;
    final tilawahTotal = logs.where((l) => l.prayer == 'tilawah').length;

    final badges = [
      ('First Step', Icons.directions_run, AppColors.primary, wajibTotal > 0),
      ('7 Day Streak', Icons.local_fire_department, AppColors.secondaryFixed, hero.best >= 7),
      ('Quran Reader', Icons.menu_book, AppColors.tertiary, tilawahTotal > 0),
      ('Dawn Patrol', Icons.wb_twilight, AppColors.primaryFixed, subuhStreak >= 7),
    ];
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACHIEVEMENTS',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: badges.map((b) {
              return Expanded(
                child: Opacity(
                  opacity: b.$4 ? 1.0 : 0.3,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: b.$3.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: b.$3.withValues(alpha: 0.4)),
                          boxShadow: b.$4
                              ? [
                                  BoxShadow(
                                    color: b.$3.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(b.$2, color: b.$3, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelCaps().copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _settings() {
    final rows = <_SettingRow>[
      _SettingRow('Pengaturan Akun', Icons.person_outline),
      _SettingRow('Notifikasi', Icons.notifications_outlined),
      _SettingRow('Tema & Tampilan', Icons.palette_outlined),
      _SettingRow('Privasi & Data', Icons.lock_outline),
      _SettingRow('Tentang Aplikasi', Icons.info_outline),
      _SettingRow('Keluar', Icons.logout, color: AppColors.error),
    ];
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          r.icon,
                          color: r.color ?? AppColors.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            r.title,
                            style: AppText.bodyLg().copyWith(
                              color: r.color ?? AppColors.onSurface,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  color: AppColors.outlineVariant,
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingRow {
  final String title;
  final IconData icon;
  final Color? color;
  _SettingRow(this.title, this.icon, {this.color});
}
