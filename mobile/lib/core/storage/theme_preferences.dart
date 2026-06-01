import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema tercihi — [SharedPreferences] ile kalıcı.
abstract final class ThemePreferences {
  static const _key = 'app_theme_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _store {
    final p = _prefs;
    if (p == null) {
      throw StateError('ThemePreferences.init() must run before use');
    }
    return p;
  }

  static ThemeMode loadThemeMode() {
    try {
      if (_prefs == null) return ThemeMode.dark;
      return _decode(_store.getString(_key));
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    await init();
    await _store.setString(_key, _encode(mode));
  }

  static String label(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Açık Tema',
        ThemeMode.dark => 'Koyu Tema',
        ThemeMode.system => 'Sistem Temasını Takip Et',
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.dark,
      };
}
