import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/theme_preferences.dart';

/// AMOLED saf siyah koyu tema — OLED ekranlarda pil tasarrufu.
final amoledDarkProvider =
    NotifierProvider<AmoledDarkNotifier, bool>(AmoledDarkNotifier.new);

class AmoledDarkNotifier extends Notifier<bool> {
  @override
  bool build() => ThemePreferences.loadAmoledDark();

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    await ThemePreferences.saveAmoledDark(enabled);
  }

  /// Sunucudan çekilen AMOLED tercihi.
  Future<void> applyLocal(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
  }

  Future<void> toggle() => setEnabled(!state);
}
