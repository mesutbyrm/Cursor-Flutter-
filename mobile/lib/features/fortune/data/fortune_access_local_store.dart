import 'package:shared_preferences/shared_preferences.dart';

/// Yerel reklam fal hakkı + günlük reklam sayacı (sunucu senkron öncesi).
class FortuneAccessLocalStore {
  FortuneAccessLocalStore(this._prefs);

  static const _adCreditsKey = 'fortune_ad_credits_v1';
  static const _adsTodayKey = 'fortune_ads_today_count_v1';
  static const _adsDayKey = 'fortune_ads_today_date_v1';

  final SharedPreferences _prefs;

  static Future<FortuneAccessLocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return FortuneAccessLocalStore(prefs);
  }

  int get adCredits => _prefs.getInt(_adCreditsKey) ?? 0;

  Future<void> setAdCredits(int value) async {
    await _prefs.setInt(_adCreditsKey, value < 0 ? 0 : value);
  }

  Future<int> addAdCredits(int delta) async {
    final next = adCredits + delta;
    await setAdCredits(next);
    return next;
  }

  Future<bool> consumeAdCredit() async {
    final cur = adCredits;
    if (cur <= 0) return false;
    await setAdCredits(cur - 1);
    return true;
  }

  int get adsWatchedToday {
    _rollDayIfNeeded();
    return _prefs.getInt(_adsTodayKey) ?? 0;
  }

  Future<int> incrementAdsWatchedToday() async {
    _rollDayIfNeeded();
    final next = adsWatchedToday + 1;
    await _prefs.setInt(_adsTodayKey, next);
    return next;
  }

  void _rollDayIfNeeded() {
    final today = _dayKey(DateTime.now());
    final stored = _prefs.getString(_adsDayKey);
    if (stored != today) {
      _prefs.setString(_adsDayKey, today);
      _prefs.setInt(_adsTodayKey, 0);
    }
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
