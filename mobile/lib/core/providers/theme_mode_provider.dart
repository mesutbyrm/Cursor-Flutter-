import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/theme_preferences.dart';

/// Uygulama tema modu — [SharedPreferences] ile kalıcı; anında güncellenir.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemePreferences.loadThemeMode();

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ThemePreferences.saveThemeMode(mode);
  }

  void toggleLightDark() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setMode(next);
  }
}
