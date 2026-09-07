import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/currency_branding_snapshot.dart';
import '../data/currency_branding_remote_datasource.dart';

const _cacheKey = 'economy_currency_branding_v1';

/// Markalama önbelleği — endpoint yoksa varsayılanlara düşer.
class CurrencyBrandingCache {
  CurrencyBrandingCache(this._remote);

  final CurrencyBrandingRemoteDataSource _remote;
  CurrencyBrandingSnapshot? _memory;

  CurrencyBrandingSnapshot get cachedOrDefaults =>
      _memory ?? CurrencyBrandingSnapshot.defaults;

  Future<CurrencyBrandingSnapshot> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _memory != null) return _memory!;

    if (!forceRefresh) {
      final fromDisk = await _readDisk();
      if (fromDisk != null) {
        _memory = fromDisk;
      }
    }

    final remote = await _remote.fetchBranding();
    if (remote != null) {
      _memory = remote;
      await _writeDisk(remote);
      return remote;
    }

    return _memory ?? CurrencyBrandingSnapshot.defaults;
  }

  Future<CurrencyBrandingSnapshot?> _readDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CurrencyBrandingSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(CurrencyBrandingSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'jeton': {
            'key': snapshot.jeton.key,
            'name': snapshot.jeton.name,
            'nameEn': snapshot.jeton.nameEn,
            'icon': snapshot.jeton.icon,
            'color': snapshot.jeton.color,
            'convertible': snapshot.jeton.convertible,
          },
          'cfc': {
            'key': snapshot.cfc.key,
            'name': snapshot.cfc.name,
            'nameEn': snapshot.cfc.nameEn,
            'icon': snapshot.cfc.icon,
            'color': snapshot.cfc.color,
            'convertible': snapshot.cfc.convertible,
          },
          'rules': {
            'convertible': snapshot.convertibleKeys,
            'rewardCurrency': snapshot.rewardCurrency,
          },
        }),
      );
    } catch (_) {}
  }
}
