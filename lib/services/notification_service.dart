import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification & Adzan Reminder service.
/// Port dari NotificationScheduler.kt + AdhanReminderReceiver.kt + BootReceiver.kt (main Kotlin).
///
/// Menggunakan flutter_local_notifications plugin (menggantikan AlarmManager manual).
/// Plugin ini otomatis handle:
/// - Notification channel setup
/// - Scheduled notifications dengan zonedSchedule
/// - Boot receiver untuk reschedule setelah reboot
///
/// Usage:
///   await NotificationService.init();
///   await NotificationService.scheduleAdhanReminders('Jakarta', timings);
///   await NotificationService.cancelAdhanReminders();
///   await NotificationService.setRemindersEnabled(true/false);

/// Jenis suara sebuah notifikasi terjadwal — menentukan channel yang dipakai
/// (suara channel Android immutable, jadi tiap jenis punya channel sendiri).
enum _NotifSound { silent, normal, adzan }

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'adhan_reminders';
  static const _channelName = 'Pengingat Adzan';
  static const _channelDesc = 'Notifikasi pengingat waktu sholat';

  // Channel terpisah untuk notifikasi saat masuk waktu adzan, dengan suara
  // adzan (res/raw/adzan.mp3). Channel Android immutable setelah dibuat,
  // makanya pakai ID baru, bukan mengubah channel lama. v2: channel v1 di
  // sebagian device terlanjur terbuat tanpa suara — di-bump + v1 dihapus.
  static const _adzanChannelId = 'adhan_sound_v2';
  static const _legacyAdzanChannelId = 'adhan_sound_v1';
  static const _adzanChannelName = 'Adzan';
  static const _adzanChannelDesc = 'Notifikasi bersuara adzan saat masuk waktu sholat';
  static const _adzanSound = RawResourceAndroidNotificationSound('adzan');

  // Channel senyap — notif muncul tanpa suara (mode suara: senyap).
  static const _silentChannelId = 'adhan_silent_v1';
  static const _silentChannelName = 'Pengingat Senyap';
  static const _silentChannelDesc = 'Notifikasi pengingat sholat tanpa suara';

  static const _prefEnabled = 'reminders_enabled';
  static const _prefCity = 'city';
  static const _prefDate = 'date';
  static const _prefTimingsPrefix = 'timing_';
  static const _prefNotifMode = 'notif_mode'; // fokus/seimbang/intensif
  static const _prefSoundMode = 'notif_sound_mode'; // senyap/suara/adzan

  static const _wajibList = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

  /// ID notifikasi tetap per sholat (index × 10, + offset reminder 0–2).
  /// String.hashCode tidak dijamin stabil antar-run, jadi jangan dipakai.
  static int _baseIdFor(String prayer) => (_wajibList.indexOf(prayer) + 1) * 10;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // ═══════════════════════════════════════════
  //  Init
  // ═══════════════════════════════════════════

  static Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create channel (Android 8+)
    await _createChannel();

    _initialized = true;
    debugPrint('[NotificationService] initialized');
  }

  static Future<void> _createChannel() async {
    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableVibration: true,
    );

    final adzanChannel = AndroidNotificationChannel(
      _adzanChannelId,
      _adzanChannelName,
      description: _adzanChannelDesc,
      importance: Importance.high,
      sound: _adzanSound,
      // Usage alarm supaya adzan tetap terdengar penuh, tidak dipotong
      // aturan suara notifikasi biasa.
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final silentChannel = AndroidNotificationChannel(
      _silentChannelId,
      _silentChannelName,
      description: _silentChannelDesc,
      importance: Importance.high,
      playSound: false,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableVibration: true,
    );

    // Setting channel gak bisa diubah setelah dibuat — buang versi lama
    // yang mungkin terlanjur soundless.
    await androidPlugin?.deleteNotificationChannel(_legacyAdzanChannelId);
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(adzanChannel);
    await androidPlugin?.createNotificationChannel(silentChannel);
  }

  /// Buka layar pengaturan sistem Android untuk channel adzan, supaya user
  /// bisa cek/atur suaranya langsung. Fallback: pengaturan notifikasi app.
  static Future<void> openChannelSettings() async {
    const pkg = 'id.muslimleveling.muslim_leveling';
    try {
      const intent = AndroidIntent(
        action: 'android.settings.CHANNEL_NOTIFICATION_SETTINGS',
        arguments: {
          'android.provider.extra.APP_PACKAGE': pkg,
          'android.provider.extra.CHANNEL_ID': _adzanChannelId,
        },
      );
      await intent.launch();
    } catch (_) {
      const fallback = AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
        arguments: {'android.provider.extra.APP_PACKAGE': pkg},
      );
      await fallback.launch();
    }
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true; // iOS or other

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Pastikan izin exact alarm (Android 12+). Tanpa izin ini zonedSchedule
  /// mode exact melempar PlatformException dan TIDAK ADA notif terjadwal
  /// sama sekali. Kalau belum diizinkan, buka halaman sistem
  /// "Alarm & pengingat". Return status akhir.
  static Future<bool> ensureExactAlarmPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true; // iOS or other

    final canExact =
        await androidPlugin.canScheduleExactNotifications() ?? false;
    if (canExact) return true;
    final granted = await androidPlugin.requestExactAlarmsPermission();
    return granted ?? false;
  }

  /// Minta pengecualian battery optimization (dialog sistem). Penyebab
  /// paling umum notif terjadwal tidak pernah muncul: OEM (Xiaomi/Oppo/
  /// Vivo/Realme dkk) membunuh alarm app yang "dioptimalkan" saat app
  /// ditutup. Return true kalau sudah dikecualikan.
  static Future<bool> ensureBatteryUnrestricted() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) return true;
      final res = await Permission.ignoreBatteryOptimizations.request();
      return res.isGranted;
    } catch (e) {
      debugPrint('[NotificationService] battery optimization check gagal: $e');
      return false;
    }
  }

  /// Jumlah notifikasi yang benar-benar terjadwal di sistem —
  /// dipakai untuk verifikasi setelah toggle diaktifkan.
  static Future<int> pendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  // ═══════════════════════════════════════════
  //  Schedule / Cancel
  // ═══════════════════════════════════════════

  /// Schedule adzan reminders for all 5 wajib prayers.
  /// [city] for notification text, [timings] map of prayer → "HH:mm".
  static Future<void> scheduleAdhanReminders(
    String city,
    Map<String, String> timings,
  ) async {
    if (!_initialized) await init();
    if (timings.isEmpty) return;

    // Cancel existing first
    await cancelAlarms();

    // Persist to prefs for reboot reschedule
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, true);
    await prefs.setString(_prefCity, city);
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await prefs.setString(_prefDate, todayStr);
    for (final prayer in _wajibList) {
      final t = timings[prayer];
      if (t != null && t.isNotEmpty) {
        await prefs.setString('$_prefTimingsPrefix$prayer', t);
      }
    }

    await _scheduleAlarms(city, timings);
    debugPrint('[NotificationService] scheduled ${timings.length} adhan reminders for $city');
  }

  /// Cancel all scheduled adhan reminders.
  static Future<void> cancelAdhanReminders() async {
    await cancelAlarms();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, false);
    debugPrint('[NotificationService] cancelled all adhan reminders');
  }

  /// Enable/disable without clearing saved timings.
  static Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);

    if (!enabled) {
      await cancelAlarms();
    } else {
      // Reschedule from saved timings
      final city = prefs.getString(_prefCity) ?? '';
      final timings = await _readTimingsFromPrefs(prefs);
      if (city.isNotEmpty && timings.isNotEmpty) {
        await _scheduleAlarms(city, timings);
      }
    }
  }

  static Future<bool> isRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  // ═══════════════════════════════════════════
  //  Notif mode (fokus/seimbang/intensif) — for Gap I
  // ═══════════════════════════════════════════

  static Future<String> getNotifMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefNotifMode) ?? 'seimbang';
  }

  static Future<void> setNotifMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNotifMode, mode);
    // Reschedule with new mode if enabled
    if (await isRemindersEnabled()) {
      final city = prefs.getString(_prefCity) ?? '';
      final timings = await _readTimingsFromPrefs(prefs);
      if (city.isNotEmpty && timings.isNotEmpty) {
        await scheduleAdhanReminders(city, timings);
      }
    }
  }

  /// Mode suara notifikasi: senyap (notif saja), suara (suara standar),
  /// adzan (suara adzan penuh saat masuk waktu sholat).
  static Future<String> getSoundMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefSoundMode) ?? 'adzan';
  }

  /// Simpan mode pengingat + mode suara sekaligus, lalu reschedule SEKALI
  /// kalau pengingat aktif — dipakai tombol Simpan di profil supaya gak
  /// reschedule dua kali.
  static Future<void> applyNotifSettings({
    required String mode,
    required String soundMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNotifMode, mode);
    await prefs.setString(_prefSoundMode, soundMode);
    if (await isRemindersEnabled()) {
      final city = prefs.getString(_prefCity) ?? '';
      final timings = await _readTimingsFromPrefs(prefs);
      if (city.isNotEmpty && timings.isNotEmpty) {
        await scheduleAdhanReminders(city, timings);
      }
    }
  }

  // ═══════════════════════════════════════════
  //  Internal: scheduling logic
  // ═══════════════════════════════════════════

  static Future<void> _scheduleAlarms(
    String city,
    Map<String, String> timings,
  ) async {
    final now = DateTime.now();
    final mode = await getNotifMode();
    final soundMode = await getSoundMode();

    for (final prayer in _wajibList) {
      final timeStr = timings[prayer];
      if (timeStr == null || timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Notification ID per prayer
      final notifId = _baseIdFor(prayer);

      // Schedule based on mode
      final schedules = _getScheduleTimes(mode, hour, minute, now);
      for (var i = 0; i < schedules.length; i++) {
        var scheduledTime = schedules[i];
        // Sudah lewat hari ini → mulai besok. Notifikasi berulang harian
        // (matchDateTimeComponents), jadi tetap bunyi walau app tak dibuka;
        // jam presisi di-refresh tiap app dibuka.
        if (!scheduledTime.isAfter(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }
        // Elemen terakhir = tepat waktu adzan. Jenis suara mengikuti
        // pilihan user: senyap semua / suara standar semua / adzan hanya
        // saat masuk waktu (pra-adzan tetap suara standar).
        final isMain = i == schedules.length - 1;
        final sound = switch (soundMode) {
          'senyap' => _NotifSound.silent,
          'suara' => _NotifSound.normal,
          _ => isMain ? _NotifSound.adzan : _NotifSound.normal,
        };
        try {
          await _scheduleOne(
            id: notifId + i, // unique ID per reminder
            title: _titleFor(prayer),
            body: _bodyFor(prayer, city, mode, i),
            scheduledTime: scheduledTime,
            sound: sound,
          );
        } catch (e) {
          // Satu reminder gagal total — lanjutkan sisanya, jangan abort.
          debugPrint('[NotificationService] gagal jadwalkan $prayer+$i: $e');
        }
      }
    }
  }

  /// Get list of scheduled times based on notif mode.
  /// Returns list of DateTime for each reminder.
  static List<DateTime> _getScheduleTimes(
    String mode,
    int hour,
    int minute,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);

    switch (mode) {
      case 'fokus':
        // At adzan time only (1 reminder)
        return [today];
      case 'intensif':
        // 30 min before + 5 min before + at adzan time (3 reminders)
        return [
          today.subtract(const Duration(minutes: 30)),
          today.subtract(const Duration(minutes: 5)),
          today,
        ];
      case 'seimbang':
      default:
        // 15 min before + at adzan time (2 reminders)
        return [
          today.subtract(const Duration(minutes: 15)),
          today,
        ];
    }
  }

  static String _titleFor(String prayer) {
    final cap = prayer[0].toUpperCase() + prayer.substring(1);
    return '🕌 Waktunya Sholat $cap';
  }

  static String _bodyFor(String prayer, String city, String mode, int reminderIndex) {
    final loc = city.isNotEmpty ? 'di $city. ' : '';
    switch (mode) {
      case 'intensif':
        if (reminderIndex == 0) return '30 menit lagi masuk waktu $prayer ${loc}Persiapan ya! 🔥';
        if (reminderIndex == 1) return '5 menit lagi masuk waktu $prayer ${loc}Segera siap! ⚡';
        return 'Sudah masuk waktu sholat $prayer ${loc}Yuk jaga streak! 🔥';
      case 'fokus':
        return 'Sudah masuk waktu sholat $prayer ${loc}Yuk jaga streak! 🔥';
      case 'seimbang':
      default:
        if (reminderIndex == 0) return '15 menit lagi masuk waktu $prayer ${loc}Persiapan ya! 🌙';
        return 'Sudah masuk waktu sholat $prayer ${loc}Yuk jaga streak! 🔥';
    }
  }

  static NotificationDetails _detailsFor(_NotifSound sound) {
    final androidDetails = AndroidNotificationDetails(
      switch (sound) {
        _NotifSound.silent => _silentChannelId,
        _NotifSound.normal => _channelId,
        _NotifSound.adzan => _adzanChannelId,
      },
      switch (sound) {
        _NotifSound.silent => _silentChannelName,
        _NotifSound.normal => _channelName,
        _NotifSound.adzan => _adzanChannelName,
      },
      channelDescription: switch (sound) {
        _NotifSound.silent => _silentChannelDesc,
        _NotifSound.normal => _channelDesc,
        _NotifSound.adzan => _adzanChannelDesc,
      },
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: sound != _NotifSound.silent,
      sound: sound == _NotifSound.adzan ? _adzanSound : null,
      audioAttributesUsage: sound == _NotifSound.adzan
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableVibration: true,
      autoCancel: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required _NotifSound sound,
  }) async {
    Future<void> schedule(AndroidScheduleMode mode, _NotifSound s) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        _detailsFor(s),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // Fallback berlapis — satu pengingat yang gagal gak boleh bikin
    // seluruh penjadwalan mati diam-diam:
    // 1) exact  2) inexact (izin "Alarm & pengingat" ditolak)
    // 3) inexact dengan suara standar (mis. resource suara adzan bermasalah).
    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle, sound);
    } on PlatformException catch (e) {
      debugPrint('[NotificationService] exact gagal (${e.code}) id=$id, '
          'coba inexact');
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle, sound);
      } on PlatformException catch (e2) {
        debugPrint('[NotificationService] inexact gagal (${e2.code}) id=$id, '
            'coba suara standar');
        await schedule(
            AndroidScheduleMode.inexactAllowWhileIdle, _NotifSound.normal);
      }
    }
  }

  static Future<void> cancelAlarms() async {
    // App ini cuma menjadwalkan pengingat adzan, jadi cancelAll aman —
    // sekaligus bersih-bersih jadwal lama ber-ID hashCode dari versi sebelumnya.
    await _plugin.cancelAll();
  }

  // ═══════════════════════════════════════════
  //  Prefs helpers
  // ═══════════════════════════════════════════

  static Future<Map<String, String>> _readTimingsFromPrefs(
    SharedPreferences prefs,
  ) async {
    final result = <String, String>{};
    for (final prayer in _wajibList) {
      final t = prefs.getString('$_prefTimingsPrefix$prayer');
      if (t != null && t.isNotEmpty) {
        result[prayer] = t;
      }
    }
    return result;
  }

  // ═══════════════════════════════════════════
  //  Notification tap handler
  // ═══════════════════════════════════════════

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] notification tapped: ${response.payload}');
    // App will open to home — could add deep linking later
  }

  /// Send a test notification (for settings dialog).
  /// Channel/suaranya mengikuti mode suara yang sedang dipilih, jadi user
  /// langsung dengar hasil setting-nya.
  static Future<void> sendTestNotification(String mode) async {
    if (!_initialized) await init();

    final message = switch (mode) {
      'fokus' => 'Mode Fokus aktif! Pengingat hanya saat masuk waktu adzan.',
      'seimbang' => 'Mode Seimbang aktif! Pengingat semua sholat wajib 15 menit sebelum adzan.',
      'intensif' => 'Mode Intensif aktif! Diingetin 30 menit & 5 menit sebelum sholat. Pertahanin streak! 🔥',
      _ => 'Notifikasi Muslim Leveling siap! 🔔',
    };

    final soundMode = await getSoundMode();
    final details = _detailsFor(switch (soundMode) {
      'senyap' => _NotifSound.silent,
      'adzan' => _NotifSound.adzan,
      _ => _NotifSound.normal,
    });

    final cap = mode[0].toUpperCase() + mode.substring(1);
    await _plugin.show(
      99,
      'Muslim Leveling Mode: $cap',
      message,
      details,
    );
  }

  /// Tes suara adzan — bunyikan notifikasi lewat channel adzan sekarang juga,
  /// supaya user bisa verifikasi suara tanpa menunggu waktu sholat.
  static Future<void> sendTestAdzanSound() async {
    if (!_initialized) await init();

    await _plugin.show(
      98,
      '🕌 Tes Suara Adzan',
      'Kalau adzan terdengar, notifikasi kamu siap! Kalau tidak, cek volume alarm HP.',
      _detailsFor(_NotifSound.adzan),
    );
  }
}
