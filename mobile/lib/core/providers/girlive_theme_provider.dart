import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/theme_preferences.dart';

/// GirLive Tema (TikTok tarzı) — seçiliyse koyu/AMOLED yerine kullanılır.
final girliveThemeProvider =
    NotifierProvider<GirLiveThemeNotifier, bool>(GirLiveThemeNotifier.new);

class GirLiveThemeNotifier extends Notifier<bool> {
  @override
  bool build() => ThemePreferences.loadGirLiveTheme();

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    await ThemePreferences.saveGirLiveTheme(enabled);
  }
}
