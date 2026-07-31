import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import '../providers/amoled_dark_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../storage/theme_preferences.dart';
import 'user_theme_remote_datasource.dart';
import 'user_theme_sync.dart';

final userThemeRemoteDataSourceProvider =
    Provider<UserThemeRemoteDataSource>((ref) {
  return UserThemeRemoteDataSource(ref.watch(dioProvider));
});

/// Oturum açıkken tema ↔ `/api/user/theme` senkronu.
final userThemeSyncProvider =
    Provider<UserThemeSyncNotifier>((ref) => UserThemeSyncNotifier(ref));

class UserThemeSyncNotifier {
  UserThemeSyncNotifier(this._ref);

  final Ref _ref;

  Future<void> pullFromServer() async {
    try {
      final remote =
          await _ref.read(userThemeRemoteDataSourceProvider).fetchTheme();
      if (remote == null) return;
      final parsed = UserThemeSync.fromServerTheme(remote);
      await ThemePreferences.saveThemeMode(parsed.mode);
      await ThemePreferences.saveAmoledDark(parsed.amoled);
      _ref.read(themeModeProvider.notifier).applyLocal(parsed.mode);
      await _ref
          .read(amoledDarkProvider.notifier)
          .applyLocal(parsed.amoled);
    } catch (_) {}
  }

  Future<void> pushCurrent() async {
    try {
      final mode = _ref.read(themeModeProvider);
      final amoled = _ref.read(amoledDarkProvider);
      await _ref.read(userThemeRemoteDataSourceProvider).updateTheme(
            UserThemeSync.toServerTheme(mode: mode, amoled: amoled),
          );
    } catch (_) {}
  }
}
