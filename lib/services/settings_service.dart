import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide preferences stored on the device.
class SettingsService extends ChangeNotifier {
  static const _themeKey = 'basecamp.themeMode';

  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final name = _prefs!.getString(_themeKey);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      debugPrint('Could not load settings: $e');
    }
    notifyListeners();
  }

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString(_themeKey, mode.name);
    notifyListeners();
  }
}
