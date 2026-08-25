import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entrance_effect_settings.dart';

const _prefsKey = 'entrance_effect_settings_v1';

final entranceEffectSettingsProvider =
    NotifierProvider<EntranceEffectSettingsNotifier, EntranceEffectSettings>(
  EntranceEffectSettingsNotifier.new,
);

class EntranceEffectSettingsNotifier extends Notifier<EntranceEffectSettings> {
  @override
  EntranceEffectSettings build() {
    Future.microtask(_load);
    return const EntranceEffectSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        state = EntranceEffectSettings.fromJson(map);
      }
    } catch (_) {}
  }

  Future<void> update(EntranceEffectSettings next) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
    } catch (_) {}
  }
}
