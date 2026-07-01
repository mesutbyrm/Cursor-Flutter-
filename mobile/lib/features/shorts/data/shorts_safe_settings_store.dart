import 'package:shared_preferences/shared_preferences.dart';

/// Kısa video çocuk güvenliği ve içerik filtreleme tercihleri.
class ShortsSafeSettingsStore {
  ShortsSafeSettingsStore._();

  static const _restrictedKey = 'shorts_restricted_mode_v1';
  static const _hideMatureKey = 'shorts_hide_mature_v1';

  static final instance = ShortsSafeSettingsStore._();

  Future<bool> isRestrictedMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_restrictedKey) ?? false;
  }

  Future<void> setRestrictedMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_restrictedKey, value);
  }

  Future<bool> hideMatureContent() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_hideMatureKey) ?? true;
  }

  Future<void> setHideMatureContent(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_hideMatureKey, value);
  }
}
