import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fortune_share_preferences.dart';

final fortuneSharePreferencesProvider =
    FutureProvider<FortuneSharePreferences>((ref) {
  return FortuneSharePreferences.create();
});

final fortuneAutoShareModeProvider =
    FutureProvider<FortuneAutoShareMode>((ref) async {
  final prefs = await ref.watch(fortuneSharePreferencesProvider.future);
  return prefs.autoShareMode;
});
