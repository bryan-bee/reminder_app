import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Named color choices for the app's theme seed. The name is what's shown
/// in the settings UI; the color drives Material 3's ColorScheme.fromSeed.
enum ThemeSeed {
  purple('Purple', Color.fromARGB(255, 106, 45, 211)),
  blue('Blue', Color.fromARGB(255, 10, 108, 187)),
  green('Green', Color.fromARGB(255, 48, 167, 52)),
  orange('Orange', Colors.deepOrange),
  pink('Pink', Color.fromARGB(255, 205, 134, 174)),
  teal('Teal', Color.fromARGB(255, 8, 177, 160));

  const ThemeSeed(this.label, this.color);
  final String label;
  final Color color;
}

/// Holds the app's theme preferences and notifies listeners (MyApp) when
/// they change, so switching a setting rebuilds the MaterialApp's theme
/// immediately without restarting the app.
class ThemeController extends ChangeNotifier {
  static const _seedKey = 'theme_seed';
  static const _modeKey = 'theme_mode';

  ThemeSeed _seed = ThemeSeed.purple;
  ThemeMode _mode = ThemeMode.system;

  ThemeSeed get seed => _seed;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final seedName = prefs.getString(_seedKey);
    if (seedName != null) {
      _seed = ThemeSeed.values.firstWhere(
        (s) => s.name == seedName,
        orElse: () => ThemeSeed.purple,
      );
    }
    final modeIndex = prefs.getInt(_modeKey);
    if (modeIndex != null && modeIndex < ThemeMode.values.length) {
      _mode = ThemeMode.values[modeIndex];
    }
    notifyListeners();
  }

  Future<void> setSeed(ThemeSeed seed) async {
    _seed = seed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seedKey, seed.name);
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, mode.index);
  }
}
