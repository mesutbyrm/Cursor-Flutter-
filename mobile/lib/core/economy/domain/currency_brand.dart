import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../images/canlifal_image_urls.dart';
import '../../util/json_util.dart';

/// Tek para birimi markası — `GET /api/currency-branding`.
class CurrencyBrand extends Equatable {
  const CurrencyBrand({
    required this.key,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.convertible,
  });

  factory CurrencyBrand.fromJson(Map<String, dynamic> json) {
    return CurrencyBrand(
      key: pick(json, ['key'])?.toString() ?? 'unknown',
      name: pick(json, ['name'])?.toString() ?? '',
      nameEn: pick(json, ['nameEn'])?.toString() ?? '',
      icon: pick(json, ['icon'])?.toString() ?? '',
      color: pick(json, ['color'])?.toString() ?? '#888888',
      convertible: json['convertible'] == true,
    );
  }

  static const jetonFallback = CurrencyBrand(
    key: 'jeton',
    name: 'Jeton',
    nameEn: 'Jeton',
    icon: '/currency/jeton.svg',
    color: '#F5C542',
    convertible: true,
  );

  static const cfcFallback = CurrencyBrand(
    key: 'cfc',
    name: 'CFC',
    nameEn: 'CFC',
    icon: '/currency/cfc.svg',
    color: '#A78BFA',
    convertible: false,
  );

  final String key;
  final String name;
  final String nameEn;
  final String icon;
  final String color;
  final bool convertible;

  String labelForLocale(Locale locale) {
    if (locale.languageCode == 'en' && nameEn.trim().isNotEmpty) {
      return nameEn;
    }
    return name.trim().isNotEmpty ? name : nameEn;
  }

  String resolveIconUrl() {
    final raw = icon.trim();
    if (raw.isEmpty) return '';
    return CanlifalImageUrls.resolve(raw);
  }

  Color resolveColor({Color fallback = const Color(0xFF888888)}) {
    return _parseHexColor(color, fallback: fallback);
  }

  @override
  List<Object?> get props =>
      [key, name, nameEn, icon, color, convertible];
}

Color _parseHexColor(String? raw, {required Color fallback}) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return fallback;
  var hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length != 6 && hex.length != 8) return fallback;
  try {
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}
