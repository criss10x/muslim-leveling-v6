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
        backgroundColor: AppColors.surfaceContainerHigh,
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
