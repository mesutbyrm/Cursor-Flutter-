import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService(this._preferences);

  final SharedPreferences _preferences;

  Future<void> writeJson(String key, Object value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? readJson(String key) {
    final String? value = _preferences.getString(key);
    if (value == null) {
      return null;
    }
    final Object? decoded = jsonDecode(value);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}
