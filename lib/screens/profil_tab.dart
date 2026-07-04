import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/city_picker.dart';
import '../../services/prayer_service.dart';
import '../../services/game_service.dart';
import '../../services/notification_service.dart';
import '../../services/achievement_service.dart';
import '../../widgets/achievement_medal.dart';
import '../../widgets/tier_avatar.dart';
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
  String _cityId = '';
  String? _avatarPath;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await GameService.load();
    await AchievementService.refresh(); // sinkron medali dengan state terkini
    final p = await SharedPreferences.getInstance();
    final loc = await PrayerService.loadLocation();
    final state = GameService.current;
    final levelInfo = GameService.getLevelInfo(state.xp);
    setState(() {
      _nickname = p.getString('nickname') ?? 'Pejuang';
      _avatarPath = p.getString('avatar_path');
      _level = levelInfo.level;
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
    final picked = await CityPicker.show(context);
    if (picked == null) return;
    await PrayerService.saveLocation(picked.id, picked.name);
    setState(() {
      _cityId = picked.id;
      _cityName = picked.name;
    });
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

  Future<void> _applyNotifSettings(bool enabled, String mode, String soundMode) async {
    try {
      if (enabled) {
        await NotificationService.applyNotifSettings(mode: mode, soundMode: soundMode);
        final n = await NotificationService.pendingCount();
        if (!mounted) return;
        _showSettingSnackbar(n > 0
            ? 'Pengingat adzan aktif: mode ${mode[0].toUpperCase()}${mode.substring(1)} — $n pengingat terjadwal 🔔'
            : 'Mode tersimpan, tapi belum ada pengingat terjadwal — cek izin notifikasi & alarm di pengaturan HP.');
      } else {
        _showSettingSnackbar('Pengingat adzan dimatikan');
      }
    } catch (e) {
      // Detail teknis ke log aja — user cukup tahu langkah selanjutnya.
      debugPrint('[Profil] gagal simpan pengaturan notif: $e');
      if (!mounted) return;
      _showSettingSnackbar('Gagal menyimpan pengaturan. Coba lagi, atau cek izin notifikasi & alarm lewat tombol Pengaturan Notifikasi Android.');
    }
  }

  Future<void> _showNotifDialog() async {
    bool enabled = await NotificationService.isRemindersEnabled();
    String mode = await NotificationService.getNotifMode();
    String soundMode = await NotificationService.getSoundMode();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
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
            content: SingleChildScrollView(
              child: Column(
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
                        try {
                          if (v) {
                            // Request permission first
                            final granted = await NotificationService.requestPermission();
                            if (!granted) {
                              _showSettingSnackbar('Izin notifikasi ditolak. Aktifkan manual di pengaturan HP.');
                              return;
                            }
                            // Tanpa izin "Alarm & pengingat" (Android 12+),
                            // penjadwalan exact gagal total — minta dulu.
                            final exactOk = await NotificationService.ensureExactAlarmPermission();
                            if (!exactOk) {
                              _showSettingSnackbar('Izin "Alarm & pengingat" belum aktif — pengingat bisa telat beberapa menit.');
                            }
                            await NotificationService.setRemindersEnabled(true);
                            // Enable pertama kali belum punya timing tersimpan di
                            // prefs — jadwalkan langsung dari jadwal kota tersimpan.
                            final loc = await PrayerService.loadLocation();
                            if (loc != null) {
                              final j = await PrayerService.fetchSchedule(
                                  cityId: loc.id, cityName: loc.name);
                              if (j != null) {
                                await NotificationService.scheduleAdhanReminders(loc.name, {
                                  'subuh': j['subuh'] ?? '',
                                  'dzuhur': j['dzuhur'] ?? '',
                                  'ashar': j['ashar'] ?? '',
                                  'maghrib': j['maghrib'] ?? '',
                                  'isya': j['isya'] ?? '',
                                });
                              }
                            }
                            // Verifikasi hasil nyata di sistem, bukan cuma
                            // status toggle.
                            final n = await NotificationService.pendingCount();
                            _showSettingSnackbar(n > 0
                                ? '$n pengingat adzan terjadwal 🔔'
                                : 'Gagal menjadwalkan pengingat — cek izin notifikasi & alarm di pengaturan HP.');
                          } else {
                            await NotificationService.setRemindersEnabled(false);
                          }
                          setSt(() => enabled = v);
                        } catch (e) {
                          // Jangan pernah diam — kegagalan apa pun harus
                          // keliatan user (detail teknis ke log aja).
                          debugPrint('[Profil] gagal ubah pengingat: $e');
                          _showSettingSnackbar('Gagal mengubah pengingat. Coba lagi, atau cek izin notifikasi & alarm di pengaturan HP.');
                        }
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
                        const SizedBox(height: AppSpacing.md),
                        Text('Suara Notifikasi', style: AppText.bodyMd().copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: AppSpacing.sm),
                        _notifModeOption('senyap', '🔕 Senyap', 'Hanya muncul notifikasi, tanpa suara', soundMode, (m) => setSt(() => soundMode = m)),
                        _notifModeOption('suara', '🔔 Suara', 'Notifikasi dengan suara standar HP', soundMode, (m) => setSt(() => soundMode = m)),
                        _notifModeOption('adzan', '🕌 Adzan', 'Suara adzan penuh saat masuk waktu sholat', soundMode, (m) => setSt(() => soundMode = m)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Test buttons
                Row(
                  children: [
                    Expanded(
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
                    Expanded(
                      child: TextButton.icon(
                        onPressed: enabled
                            ? () async {
                                await NotificationService.sendTestAdzanSound();
                              }
                            : null,
                        icon: Icon(Icons.volume_up, size: 16, color: enabled ? AppColors.secondaryFixed : AppColors.onSurfaceVariant),
                        label: Text('Tes Adzan', style: AppText.bodyMd().copyWith(
                          color: enabled ? AppColors.secondaryFixed : AppColors.onSurfaceVariant,
                        )),
                      ),
                    ),
                  ],
                ),
                // Jalan pintas ke pengaturan channel notifikasi Android —
                // suara channel cuma bisa diubah user lewat sistem.
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => NotificationService.openChannelSettings(),
                    icon: const Icon(Icons.settings, size: 16, color: AppColors.onSurfaceVariant),
                    label: Text('Pengaturan Notifikasi Android', style: AppText.bodyMd().copyWith(
                      color: AppColors.onSurfaceVariant,
                    )),
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
              FilledButton(
                onPressed: () {
                  // Tutup dialog dulu biar tombol terasa responsif; kerja
                  // async (reschedule bisa >1 detik) jalan setelahnya, dan
                  // exception apa pun berujung snackbar, bukan diam.
                  Navigator.pop(ctx);
                  _applyNotifSettings(enabled, mode, soundMode);
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
      backgroundColor: Colors.transparent,
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
              _achievements(),
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
    final state = GameService.current;
    final levelInfo = GameService.getLevelInfo(state.xp);
    final rankTitle = GameService.getRankTitle(state.level);

    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.primary.withValues(alpha: 0.25),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showAvatarOptions,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: TierProfileAvatar(
                        profileImagePath: _avatarPath,
                        tierName: getTierName(_level),
                        sizeDp: 72,
                        showEditBadge: true,
                        onTap: _showAvatarOptions,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.primary, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'LVL $_level',
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
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
                      style: AppText.headlineMd().copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.secondaryFixed.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        rankTitle,
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.secondaryFixed,
                          fontSize: 10,
                        ),
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
          // XP Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${levelInfo.xpInCurrentLevel}/${levelInfo.xpNeededForNextLevel} XP',
                    style: AppText.bodyMd().copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: levelInfo.progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryFixed],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
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
      ),
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
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppText.titleLg().copyWith(color: color, fontSize: 24),
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

  /// Grid medali achievement ala Mobile Legends. Tap medali → detail.
  Widget _achievements() {
    final defs = AchievementService.defs;
    final unlockedCount = AchievementService.unlockedCount;

    return GlassPanel(
      borderColor: AppColors.secondaryFixed.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: AppColors.secondaryFixed, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'ACHIEVEMENTS',
                style: AppText.labelCaps()
                    .copyWith(color: AppColors.secondaryFixed),
              ),
              const Spacer(),
              Text(
                '$unlockedCount/${defs.length}',
                style: AppText.labelCaps().copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.xs,
            childAspectRatio: 0.72,
            children: defs.map((d) {
              final unlocked = AchievementService.isUnlocked(d.id);
              return PressableScale(
                onTap: () => showAchievementDetail(
                  context,
                  d,
                  unlocked: unlocked,
                  unlockedDate: AchievementService.unlockedDate(d.id),
                ),
                child: Column(
                  children: [
                    AchievementMedal(def: d, unlocked: unlocked, size: 60),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        d.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelCaps().copyWith(
                          fontSize: 8,
                          color: unlocked
                              ? tierColors(d.tier).$1
                              : AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
                'BADGES',
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (r.color ?? AppColors.onSurface).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            r.icon,
                            color: r.color ?? AppColors.onSurface,
                            size: 20,
                          ),
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
