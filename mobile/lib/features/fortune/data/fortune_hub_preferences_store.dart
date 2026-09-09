import 'package:shared_preferences/shared_preferences.dart';

/// Fal hub yerel tercihler — son fal, hatırlatıcı.
class FortuneHubPreferencesStore {
  FortuneHubPreferencesStore(this._prefs);

  static const _lastSlugKey = 'fortune_hub_last_slug_v1';
  static const _lastTitleKey = 'fortune_hub_last_title_v1';
  static const _reminderKey = 'fortune_daily_reminder_v1';

  final SharedPreferences _prefs;

  static Future<FortuneHubPreferencesStore> create() async {
    return FortuneHubPreferencesStore(await SharedPreferences.getInstance());
  }

  String? get lastFortuneSlug => _prefs.getString(_lastSlugKey);

  String? get lastFortuneTitle => _prefs.getString(_lastTitleKey);

  bool get dailyReminderEnabled => _prefs.getBool(_reminderKey) ?? false;

  Future<void> saveLastFortune({
    required String slug,
    required String title,
  }) async {
    await _prefs.setString(_lastSlugKey, slug);
    await _prefs.setString(_lastTitleKey, title);
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    await _prefs.setBool(_reminderKey, value);
  }

  Future<void> clear() async {
    await _prefs.remove(_lastSlugKey);
    await _prefs.remove(_lastTitleKey);
    await _prefs.remove(_reminderKey);
  }
}
