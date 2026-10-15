import 'package:flutter/material.dart';

import 'user_theme_remote_datasource.dart';

/// Yerel tema ↔ sunucu `theme` alanı eşlemesi.
abstract final class UserThemeSync {
  static String toServerTheme({
    required ThemeMode mode,
    required bool amoled,
  }) {
    if (mode == ThemeMode.light) return 'light';
    if (amoled) return 'amoled';
    return 'dark';
  }

  static ({ThemeMode mode, bool amoled}) fromServerTheme(String? raw) {
    final theme = (raw ?? 'dark').trim().toLowerCase();
    return switch (theme) {
      'light' => (mode: ThemeMode.light, amoled: false),
      'amoled' || 'amoled-dark' || 'oled' => (mode: ThemeMode.dark, amoled: true),
      _ => (mode: ThemeMode.dark, amoled: false),
    };
  }

  /// Uygulama temasına ait değer mi? Sunucu web temalarını da (`mystical`,
  /// `facebook`) döndürür; bunlar uygulamadaki seçimi SIFIRLAMAMALI.
  static bool isAppTheme(String? raw) {
    final t = (raw ?? '').trim().toLowerCase();
    return const {'light', 'dark', 'amoled', 'amoled-dark', 'oled'}.contains(t);
  }

  static Future<void> pullFromServer(UserThemeRemoteDataSource ds) async {
    final remote = await ds.fetchTheme();
    if (remote == null) return;
    // Çağıran notifier yerel tercihi günceller.
  }
}
