import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_cache.dart';

const _themeModeKey = 'app_theme_mode';

/// Uygulama tema modu — Hive ile kalıcı; varsayılan koyu.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _readPersisted();

  ThemeMode _readPersisted() {
    try {
      return _decode(LocalCache.getString(_themeModeKey));
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      await LocalCache.setString(_themeModeKey, _encode(mode));
    } catch (_) {}
  }

  void toggleLightDark() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setMode(next);
  }
}

String _encode(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

ThemeMode _decode(String? raw) => switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
