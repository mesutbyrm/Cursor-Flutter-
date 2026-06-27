import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// GET yanıtları için TTL'li offline önbellek (feed, profil, oda listesi).
abstract final class ApiCacheStore {
  static const _prefix = 'api_cache_v1_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<T?> read<T>(
    String key,
    T Function(Map<String, dynamic> json) decode, {
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    await init();
    final raw = _prefs!.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(envelope['savedAt']?.toString() ?? '');
      if (savedAt == null ||
          DateTime.now().difference(savedAt) > maxAge) {
        await _prefs!.remove('$_prefix$key');
        return null;
      }
      final data = envelope['data'];
      if (data is! Map) return null;
      return decode(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, Map<String, dynamic> data) async {
    await init();
    final envelope = {
      'savedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    await _prefs!.setString('$_prefix$key', jsonEncode(envelope));
  }

  static Future<void> clear(String key) async {
    await init();
    await _prefs!.remove('$_prefix$key');
  }

  /// TTL'siz ham JSON gövdesi (HTTP cache katmanı).
  static Future<String?> readRaw(
    String key, {
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    await init();
    final raw = _prefs!.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(envelope['savedAt']?.toString() ?? '');
      if (savedAt == null ||
          DateTime.now().difference(savedAt) > maxAge) {
        await _prefs!.remove('$_prefix$key');
        return null;
      }
      return envelope['body']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeRaw(String key, String body) async {
    await init();
    final envelope = {
      'savedAt': DateTime.now().toIso8601String(),
      'body': body,
    };
    await _prefs!.setString('$_prefix$key', jsonEncode(envelope));
  }

  static Future<void> clearRaw(String key) async {
    await clear(key);
  }

  static Future<void> clearByPrefix(String prefix) async {
    await init();
    final fullPrefix = '$_prefix$prefix';
    final keys =
        _prefs!.getKeys().where((k) => k.startsWith(fullPrefix)).toList();
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }

  static Future<void> clearAll() async {
    await init();
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }
}
