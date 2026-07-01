import 'package:shared_preferences/shared_preferences.dart';

/// Keşfet ekranında seçilen konum tercihi.
class ShortExploreLocationStore {
  ShortExploreLocationStore._();

  static final ShortExploreLocationStore instance = ShortExploreLocationStore._();

  static const _labelKey = 'short_explore_location_label_v1';
  static const _latKey = 'short_explore_location_lat_v1';
  static const _lngKey = 'short_explore_location_lng_v1';

  Future<({String? label, double? lat, double? lng})> read() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString(_labelKey);
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    return (label: label, lat: lat, lng: lng);
  }

  Future<void> save({
    required String label,
    double? lat,
    double? lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_labelKey, label.trim());
    if (lat != null) {
      await prefs.setDouble(_latKey, lat);
    } else {
      await prefs.remove(_latKey);
    }
    if (lng != null) {
      await prefs.setDouble(_lngKey, lng);
    } else {
      await prefs.remove(_lngKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_labelKey);
    await prefs.remove(_latKey);
    await prefs.remove(_lngKey);
  }
}
