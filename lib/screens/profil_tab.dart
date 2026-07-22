import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/city_picker.dart';
import '../../services/prayer_service.dart';
import '../../services/game_service.dart';
import '../../services/notification_service.dart';
import '../../services/achievement_service.dart';
import '../../services/learning_content.dart';
import '../../services/supabase_sync.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/achievement_medal.dart';
import '../../widgets/tier_avatar.dart';
import 'achievements_screen.dart';
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
  bool _haidMode = false;

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChange);
    _loadProfile();
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

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
      _haidMode = state.haidMode;
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
            focusedBorder: UnderlineInputBorder(
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
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Ganti Foto', style: AppText.bodyLg()),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar();
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
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
        backgroundColor: AppColors.surfaceContainerLowest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  /// Ringkas exception buat snackbar diagnosa: tipe + potongan pesan.
  String _shortError(Object e) {
    final s = e.toString();
    return s.length > 110 ? '${s.substring(0, 110)}…' : s;
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
    } catch (e, st) {
      // Tampilkan error asli (dipendekkan) — sebelumnya disembunyikan dan
      // bikin debugging buta. Full stacktrace ke Sentry.
      debugPrint('[Profil] gagal simpan pengaturan notif: $e');
      await Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      _showSettingSnackbar('Gagal menyimpan: ${_shortError(e)}');
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
                            // Battery optimization = penyebab #1 notif
                            // terjadwal tak pernah muncul saat app ditutup.
                            final battOk = await NotificationService.ensureBatteryUnrestricted();
                            if (!battOk) {
                              _showSettingSnackbar('Izinkan "Tanpa batasan baterai" supaya pengingat tetap bunyi saat app ditutup.');
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
                        } catch (e, st) {
                          // Jangan pernah diam — tampilkan error asli
                          // (dipendekkan), full stacktrace ke Sentry.
                          debugPrint('[Profil] gagal ubah pengingat: $e');
                          await Sentry.captureException(e, stackTrace: st);
                          _showSettingSnackbar('Gagal mengubah pengingat: ${_shortError(e)}');
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
                                // Tes = preview murni; tidak menyimpan/
                                // reschedule (itu tugas Simpan). Dulu tombol
                                // ini mati diam-diam saat reschedule throw.
                                try {
                                  await NotificationService.sendTestNotification(
                                      mode, soundModeOverride: soundMode);
                                } catch (e, st) {
                                  debugPrint('[Profil] tes notif gagal: $e');
                                  await Sentry.captureException(e, stackTrace: st);
                                  _showSettingSnackbar('Tes notifikasi gagal: ${_shortError(e)}');
                                }
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
                    icon: Icon(Icons.settings, size: 16, color: AppColors.onSurfaceVariant),
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
          color: selected
              ? (isLightTheme
                  ? AppColors.primaryContainer
                  : AppColors.primaryContainer.withValues(alpha: 0.15))
              : Colors.transparent,
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
              _achievements(),
              const SizedBox(height: AppSpacing.lg),
              _haidModeToggle(),
              const SizedBox(height: AppSpacing.md),
              _accountBackup(),
              const SizedBox(height: AppSpacing.md),
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
                        Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _nickname,
                            style: AppText.headlineMd().copyWith(fontSize: 22),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: GestureDetector(
                            onTap: _editNickname,
                            child: Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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
                        gradient: LinearGradient(
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
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          // Location row — editable
          InkWell(
            onTap: _editLocation,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 18),
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
                  Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _miniStat('Level', '${GameService.current.level}')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _miniStat('XP', '${GameService.current.xp}')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _miniStat('Streak', '${GameService.current.heroStreak.current}🔥')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _miniStat('Rank', GameService.getRankTitle(GameService.current.level))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.titleLg().copyWith(color: AppColors.primary),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HudHeader('STATISTIK'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            _statCard('Sholat Selesai', '$wajibTotal', 'total', Icons.mosque, AppColors.primary),
            _statCard('Tilawah', '$tilawahTotal', 'kali', Icons.menu_book, AppColors.tertiary),
            _statCard('Sunnah', '$sunnahTotal', 'total', Icons.volunteer_activism, AppColors.secondaryFixed),
            _statCard('Hero Streak', '${GameService.current.heroStreak.current}', 'hari', Icons.local_fire_department, AppColors.secondaryFixed),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, String sub, IconData icon, Color color) {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
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
            style: AppText.displayHero(28).copyWith(color: color, height: 1.1),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HudHeader('STREAK PER SHOLAT'),
        FlatCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: prayers.map((entry) {
              final label = entry.$1;
              final count = streaks[entry.$2]?.current ?? 0;
              final active = count > 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppText.labelCaps().copyWith(
                      color: active
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 13,
                        color: active
                            ? AppColors.secondaryFixed
                            : AppColors.outlineVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$count',
                        style: AppText.titleLg().copyWith(
                          fontSize: 15,
                          color: active
                              ? AppColors.secondaryFixed
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Ringkasan medali + pintu ke galeri.
  /// Dulu 43 medali digelar penuh di sini: tab Profil jadi panjang dan
  /// medalinya mengecil. Sekarang cukup cuplikan + progres; galeri lengkap
  /// (dikelompokkan per tier) ada di [AchievementsScreen].
  Widget _achievements() {
    final defs = AchievementService.defs;
    final unlockedCount = AchievementService.unlockedCount;

    // Cuplikan: yang sudah terbuka lebih dulu, sisanya ditambal yang terkunci
    // supaya barisnya tidak pernah kosong di akun baru.
    final preview = <AchievementDef>[
      ...defs.where((d) => AchievementService.isUnlocked(d.id)),
      ...defs.where((d) => !AchievementService.isUnlocked(d.id)),
    ].take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader('ACHIEVEMENTS',
            meta: '$unlockedCount/${defs.length}',
            accent: AppColors.secondaryFixed),
        PressableScale(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            );
            // Medali bisa terbuka saat di galeri — segarkan hitungannya.
            if (mounted) setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                for (final d in preview)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: AchievementMedal(
                      def: d,
                      unlocked: AchievementService.isUnlocked(d.id),
                      size: 36,
                    ),
                  ),
                // Expanded menyerap sisa ruang: teks rapat ke kanan dan tidak
                // pernah overflow di layar sempit.
                Expanded(
                  child: Text(
                    'Lihat semua',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.secondaryFixed),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _haidModeToggle() {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.bloodtype_outlined, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode Haid', style: AppText.bodyLg()),
                Text(
                  _haidMode ? 'Streak dijaga — tidak ada penalti' : 'Nonaktif',
                  style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: _haidMode,
            onChanged: (v) async {
              await GameService.setHaidMode(v);
              setState(() => _haidMode = v);
            },
            activeTrackColor: AppColors.error.withValues(alpha: 0.5),
            activeThumbColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  // ── Backup & Account ──
  Future<void> _handleGoogleLogin() async {
    final uid = await AuthService.signInWithGoogle();
    if (uid == null) {
      final err = AuthService.lastError ?? 'Login Google dibatalkan atau gagal.';
      _showSettingSnackbar('❌ $err');
      return;
    }
    SupabaseSync.initWithUser(uid);

    // Pastikan cache lokal terisi dulu (source of truth di device)
    await GameService.load();
    await LearningService.load();
    await AchievementService.load(force: true);

    final remote = await SupabaseSync.load();
    final hasRemoteGame = remote != null && remote['game'] is Map;
    final hasRemoteLearning = remote != null && remote['learning'] is Map;
    final hasRemoteAchievements = remote != null && remote['achievements'] is Map;

    final p = await SharedPreferences.getInstance();
    if (hasRemoteGame) {
      await p.setString('game_state_v1', jsonEncode(remote!['game']));
    }
    if (hasRemoteLearning) {
      await p.setString('learning_state_v1', jsonEncode(remote!['learning']));
    }
    if (hasRemoteAchievements) {
      // AchievementService key = achievements_unlocked, value = {id: yyyy-MM-dd}
      final ach = remote!['achievements'];
      final unlocked = (ach is Map && ach['unlocked'] is Map)
          ? ach['unlocked']
          : ach;
      if (unlocked is Map) {
        await p.setString('achievements_unlocked', jsonEncode(unlocked));
      }
    }

    // Reload setelah write remote → local
    await GameService.load();
    await LearningService.load();
    await AchievementService.load(force: true);

    // Kalau cloud kosong: push progress lokal biar backup mulai jalan
    if (!hasRemoteGame) {
      await SupabaseSync.saveGame(GameService.current.toMap());
    }
    if (!hasRemoteLearning) {
      await SupabaseSync.saveLearning(LearningService.current.toMap());
    }
    if (!hasRemoteAchievements) {
      final raw = p.getString('achievements_unlocked');
      Map<String, dynamic> unlockedMap = {};
      if (raw != null && raw.isNotEmpty) {
        try {
          unlockedMap = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        } catch (_) {}
      }
      await SupabaseSync.saveAchievements({
        'unlocked': unlockedMap,
        'ts': DateTime.now().toUtc().toIso8601String(),
      });
    }

    if (!mounted) return;
    setState(() {});
    await _loadProfile();
    _showSettingSnackbar(
      hasRemoteGame || hasRemoteLearning || hasRemoteAchievements
          ? '☁️ Login berhasil! Progress cloud dipulihkan.'
          : '☁️ Login berhasil! Progress perangkat di-backup ke cloud.',
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.signOut();
    // Kembali ke device_id lokal (progress tetap utuh di SharedPreferences)
    final p = await SharedPreferences.getInstance();
    final deviceId = p.getString('device_id');
    if (deviceId != null) SupabaseSync.init(deviceId);
    if (!mounted) return;
    setState(() {});
    _showSettingSnackbar('Logout berhasil. Progress tersimpan di perangkat ini.');
  }

  Widget _accountBackup() {
    final signedIn = AuthService.isSignedIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HudHeader('BACKUP & AKUN'),
        FlatCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    signedIn ? Icons.cloud_done : Icons.cloud_off,
                    color: signedIn ? AppColors.primary : AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      signedIn
                          ? 'Progress tersinkron ke akun Google'
                          : 'Belum login — progress hanya di perangkat ini',
                      style: AppText.bodyMd().copyWith(
                        color: signedIn ? AppColors.primary : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (signedIn)
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar dari Akun'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 22),
                  label: const Text('Lanjut dengan Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                signedIn
                    ? 'Ganti HP? Login pakai akun sama untuk restore otomatis.'
                    : 'Login agar progress aman saat ganti HP atau instal ulang.',
                style: AppText.bodyMd().copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settings() {
    final rows = <_SettingRow>[
      _SettingRow('Pengaturan Akun', Icons.person_outline, onTap: _editNickname),
      _SettingRow('Notifikasi', Icons.notifications_outlined, onTap: _showNotifDialog),
      _SettingRow('Tema Terang', Icons.light_mode_outlined, trailing: _ThemeToggle()),
      _SettingRow('Privasi & Data', Icons.lock_outline, onTap: _showPrivacyDialog),
      _SettingRow('Tentang Aplikasi', Icons.info_outline, onTap: _showAboutDialog),
      _SettingRow('Keluar', Icons.logout, color: AppColors.error, onTap: _confirmLogout),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HudHeader('PENGATURAN'),
        FlatCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final isLast = i == rows.length - 1;
              final color = r.color ?? AppColors.onSurface;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: r.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        child: Row(
                          children: [
                            Icon(r.icon, color: color, size: 20),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                r.title,
                                style: AppText.bodyLg().copyWith(color: color),
                              ),
                            ),
                            r.trailing ??
                              Icon(
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
                    Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingRow {
  final String title;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;
  _SettingRow(this.title, this.icon, {this.color, this.onTap, this.trailing});
}

class _ThemeToggle extends StatefulWidget {
  @override
  State<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<_ThemeToggle> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: themeNotifier.isLight,
      onChanged: (_) => themeNotifier.toggle(),
      activeColor: AppColors.primary,
    );
  }
}
