import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Persists light/dark choice. Singleton so any widget can listen.
class ThemeNotifier extends ChangeNotifier {
  static const _prefKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isLight => _mode == ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'light') {
      _mode = ThemeMode.light;
      isLightTheme = true;
    } else {
      _mode = ThemeMode.dark;
      isLightTheme = false;
    }
    _updateSystemUi();
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = (_mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    isLightTheme = _mode == ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _mode == ThemeMode.light ? 'light' : 'dark');
    _updateSystemUi();
    notifyListeners();
  }

  void _updateSystemUi() {
    try {
      final isLight = _mode == ThemeMode.light;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isLight ? AppColorsLight.surface : AppColorsDark.background,
          systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        ),
      );
    } catch (_) {}
  }
}

final ThemeNotifier themeNotifier = ThemeNotifier();
