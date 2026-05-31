import 'package:hive_flutter/hive_flutter.dart';

/// Yerel önbellek — tema, son feed zamanı, offline bayrakları.
abstract final class LocalCache {
  static const _boxName = 'canlifal_cache';
  static Box<dynamic>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Box<dynamic> get box {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('LocalCache.init() must run before use');
    }
    return b;
  }

  static Future<void> setString(String key, String value) async {
    await box.put(key, value);
  }

  static String? getString(String key) => box.get(key) as String?;

  static Future<void> setBool(String key, bool value) async {
    await box.put(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return box.get(key, defaultValue: defaultValue) as bool;
  }
}
