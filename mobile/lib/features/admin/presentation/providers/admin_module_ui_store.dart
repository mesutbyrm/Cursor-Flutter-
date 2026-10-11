import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Admin modül listeleri — kaydırma ve filtre (SharedPreferences).
class AdminModuleUiStore {
  AdminModuleUiStore._();

  static const _key = 'admin_module_ui_v1';

  static Future<Map<String, dynamic>> loadAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  static Future<void> saveScroll(String module, double offset) async {
    if (module.trim().isEmpty || offset < 0) return;
    final all = await loadAll();
    final scrolls = _scrollMap(all);
    scrolls[module] = offset;
    all['scroll'] = scrolls;
    await _persist(all);
  }

  static Future<void> saveFilter(String module, String filter) async {
    if (module.trim().isEmpty) return;
    final all = await loadAll();
    final filters = _filterMap(all);
    filters[module] = filter;
    all['filter'] = filters;
    await _persist(all);
  }

  static double scrollFor(Map<String, dynamic> all, String module) {
    final v = _scrollMap(all)[module];
    if (v is num) return v.toDouble();
    return 0;
  }

  static String? filterFor(Map<String, dynamic> all, String module) {
    final v = _filterMap(all)[module];
    return v?.toString();
  }

  static Map<String, dynamic> _scrollMap(Map<String, dynamic> all) {
    final raw = all['scroll'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static Map<String, dynamic> _filterMap(Map<String, dynamic> all) {
    final raw = all['filter'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static Future<void> _persist(Map<String, dynamic> all) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(all));
  }
}
