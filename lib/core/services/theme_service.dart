import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeService(this._prefs);

  ThemeMode get themeMode {
    final value = _prefs.getString(_themeKey) ?? 'light';
    return ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$value',
      orElse: () => ThemeMode.light,
    );
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.toString().split('.').last);
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
