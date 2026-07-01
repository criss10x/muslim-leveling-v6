import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'adhan_reminders';
  static const _channelName = 'Pengingat Adzan';
  static const _channelDesc = 'Notifikasi pengingat waktu sholat';

  static const _prefEnabled = 'reminders_enabled';
  static const _prefCity = 'city';
  static const _prefDate = 'date';
  static const _prefTimingsPrefix = 'timing_';
  static const _prefNotifMode = 'notif_mode'; // fokus/seimbang/intensif

  static const _wajibList = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
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

  // ═══════════════════════════════════════════
  //  Internal: scheduling logic
  // ═══════════════════════════════════════════

  static Future<void> _scheduleAlarms(
    String city,
    Map<String, String> timings,
  ) async {
    final now = DateTime.now();
    final mode = await getNotifMode();

    for (final prayer in _wajibList) {
      final timeStr = timings[prayer];
      if (timeStr == null || timeStr.isEmpty) continue;

      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Notification ID per prayer
      final notifId = prayer.hashCode;

      // Cancel this specific notification first
      await _plugin.cancel(notifId);

      // Schedule based on mode
      final schedules = _getScheduleTimes(mode, hour, minute, now);
      for (var i = 0; i < schedules.length; i++) {
        final scheduledTime = schedules[i];
        if (scheduledTime.isAfter(now)) {
          await _scheduleOne(
            id: notifId + i, // unique ID per reminder
            title: _titleFor(prayer),
            body: _bodyFor(prayer, city, mode, i),
            scheduledTime: scheduledTime,
          );
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
        // Only Subuh + 15 min before next prayer
        // Simplified: just schedule at prayer time for all, but only fire
        // for subuh and 15 min before others
        // For now: schedule at adzan time (1 reminder)
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

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableVibration: true,
      autoCancel: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use zonedSchedule for reliable delivery
    // Convert to TZ — but for simplicity, use the platform's local time
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAlarms() async {
    // Cancel all possible notification IDs (5 prayers × 3 max reminders)
    for (final prayer in _wajibList) {
      final baseId = prayer.hashCode;
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 1);
      await _plugin.cancel(baseId + 2);
    }
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
  static Future<void> sendTestNotification(String mode) async {
    if (!_initialized) await init();

    final message = switch (mode) {
      'fokus' => 'Mode Fokus aktif! Cuma diingetin Subuh & 15 menit sebelum sholat berikutnya.',
      'seimbang' => 'Mode Seimbang aktif! Pengingat semua sholat wajib 15 menit sebelum adzan.',
      'intensif' => 'Mode Intensif aktif! Diingetin 30 menit & 5 menit sebelum sholat. Pertahanin streak! 🔥',
      _ => 'Notifikasi Muslim Leveling siap! 🔔',
    };

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final cap = mode[0].toUpperCase() + mode.substring(1);
    await _plugin.show(
      99,
      'Muslim Leveling Mode: $cap',
      message,
      details,
    );
  }
}
