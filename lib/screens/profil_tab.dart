import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/prayer_service.dart';
import '../../services/game_service.dart';
import '../../services/notification_service.dart';
import 'statistik_sheet.dart';
import 'welcome_pejuang.dart';


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

  void _showSettingSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: AppText.bodyMd().copyWith(color: AppColors.onSurface)),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  void _showNotifDialog() {
    bool enabled = false;
    String mode = 'seimbang';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          // Load initial values on first build
          if (!enabled && mode == 'seimbang') {
            NotificationService.isRemindersEnabled().then((v) {
              if (mounted) setSt(() => enabled = v);
            });
            NotificationService.getNotifMode().then((m) {
              if (mounted) setSt(() => mode = m);
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
            title: Row(
              children: [
                Icon(Icons.notifications_active, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text('Pengingat Adzan', style: AppText.bodyLg().copyWith(color: AppColors.onSurface)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle enable
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Aktifkan pengingat',
                        style: AppText.bodyMd().copyWith(color: AppColors.onSurface),
                      ),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: (v) async {
                        if (v) {
                          // Request permission first
                          final granted = await NotificationService.requestPermission();
                          if (!granted) {
                            _showSettingSnackbar('Izin notifikasi ditolak. Aktifkan manual di pengaturan HP.');
                            return;
                          }
                          await NotificationService.setRemindersEnabled(true);
                        } else {
                          await NotificationService.setRemindersEnabled(false);
                        }
                        setSt(() => enabled = v);
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Mode selection
                AnimatedOpacity(
                  opacity: enabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: AbsorbPointer(
                    absorbing: !enabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mode Pengingat', style: AppText.bodyMd().copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: AppSpacing.sm),
                        _notifModeOption('fokus', '🎯 Fokus', 'Hanya pengingat utama di waktu adzan', mode, (m) => setSt(() => mode = m)),
                        _notifModeOption('seimbang', '⚖️ Seimbang', 'Diingetin 15 menit sebelum & saat adzan', mode, (m) => setSt(() => mode = m)),
                        _notifModeOption('intensif', '🔥 Intensif', '30 menit, 5 menit sebelum & saat adzan', mode, (m) => setSt(() => mode = m)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Test button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: enabled
                        ? () async {
                            await NotificationService.setNotifMode(mode);
                            await NotificationService.sendTestNotification(mode);
                          }
                        : null,
                    icon: Icon(Icons.send, size: 16, color: enabled ? AppColors.primary : AppColors.onSurfaceVariant),
                    label: Text('Tes Notifikasi', style: AppText.bodyMd().copyWith(
                      color: enabled ? AppColors.primary : AppColors.onSurfaceVariant,
                    )),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
              ),
              FilledButton(
                onPressed: () async {
                  if (enabled) {
                    await NotificationService.setNotifMode(mode);
                    _showSettingSnackbar('Pengingat adzan aktif: mode ${mode[0].toUpperCase()}${mode.substring(1)} 🔔');
                  } else {
                    _showSettingSnackbar('Pengingat adzan dimatikan');
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text('Simpan', style: AppText.bodyMd().copyWith(color: AppColors.onPrimary)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _notifModeOption(String value, String label, String desc, String current, ValueChanged<String> onTap) {
    final selected = value == current;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  )),
                  Text(desc, style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Privasi & Data', style: AppText.titleLg()),
        content: Text(
          'Data sholat, lokasi, dan profil kamu disimpan hanya di perangkat ini. '
          'Kami tidak mengirim data pribadi ke server pihak ketiga.',
          style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Oke', style: AppText.bodyMd().copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Tentang Aplikasi', style: AppText.titleLg()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muslim Leveling', style: AppText.headlineMd().copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('Versi 1.0.0\nDibangun untuk membantu menjaga ibadah harian dengan gamifikasi.', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: AppText.bodyMd().copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text('Keluar', style: AppText.titleLg()),
        content: Text('Hapus data lokal dan kembali ke layar awal?', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: AppText.bodyMd().copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final p = await SharedPreferences.getInstance();
    await p.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePejuangScreen()),
      (route) => false,
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
    final unlocked = GameService.current.badges.toSet();
    final defs = GameService.badgeDefs;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ACHIEVEMENTS',
                style: AppText.labelCaps().copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                '${unlocked.length}/${defs.length}',
                style: AppText.labelCaps().copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.xs,
            childAspectRatio: 0.82,
            children: defs.map((b) {
              final isUnlocked = unlocked.contains(b.$1);
              return _badgeTile(
                emoji: b.$3,
                title: b.$2,
                desc: b.$4,
                unlocked: isUnlocked,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile({
    required String emoji,
    required String title,
    required String desc,
    required bool unlocked,
  }) {
    return Tooltip(
      message: unlocked ? desc : '???',
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.35,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (unlocked ? AppColors.primary : AppColors.onSurfaceVariant)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (unlocked ? AppColors.primary : AppColors.onSurfaceVariant)
                      .withValues(alpha: 0.4),
                ),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  unlocked ? emoji : '🔒',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelCaps().copyWith(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settings() {
    final rows = <_SettingRow>[
      _SettingRow('Pengaturan Akun', Icons.person_outline, onTap: _editNickname),
      _SettingRow('Notifikasi', Icons.notifications_outlined, onTap: _showNotifDialog),
      _SettingRow('Tema & Tampilan', Icons.palette_outlined, onTap: () => _showSettingSnackbar('Saat ini hanya tema gelap yang tersedia')),
      _SettingRow('Privasi & Data', Icons.lock_outline, onTap: _showPrivacyDialog),
      _SettingRow('Tentang Aplikasi', Icons.info_outline, onTap: _showAboutDialog),
      _SettingRow('Keluar', Icons.logout, color: AppColors.error, onTap: _confirmLogout),
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
                  onTap: r.onTap,
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
  final VoidCallback? onTap;
  _SettingRow(this.title, this.icon, {this.color, this.onTap});
}
