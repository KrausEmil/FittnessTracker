import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme_options.dart';

class AppState extends ChangeNotifier {
  static const _restDurationKey = 'rest_duration';
  static const _themeIndexKey = 'theme_index';

  int _themeIndex;
  int _restDuration;

  AppState({required int initialThemeIndex, required int initialRestDuration})
    : _themeIndex = normalizeThemeIndex(initialThemeIndex),
      _restDuration = initialRestDuration;

  int get themeIndex => _themeIndex;
  int get restDuration => _restDuration;

  Future<void> setThemeIndex(int value) async {
    final normalized = normalizeThemeIndex(value);
    if (normalized == _themeIndex) {
      return;
    }

    _themeIndex = normalized;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeIndexKey, normalized);
  }

  Future<void> setRestDuration(int value) async {
    final clamped = value.clamp(10, 300).toInt();
    if (clamped == _restDuration) {
      return;
    }

    _restDuration = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restDurationKey, clamped);
  }
}
