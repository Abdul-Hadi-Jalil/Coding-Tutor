import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark; // default to dark

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get mode => _mode;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    if (value == 'light') {
      _mode = ThemeMode.light;
    } else {
      // default or 'dark'
      _mode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    // persist asynchronously without blocking UI
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKey, _mode == ThemeMode.dark ? 'dark' : 'light');
    });
    notifyListeners();
  }
}