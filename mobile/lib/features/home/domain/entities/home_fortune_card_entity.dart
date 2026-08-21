import 'package:flutter/material.dart';

import '../../../../core/util/fortune_price_parser.dart';

/// Ana sayfa fal vitrin kartı — `GET /api/homepage-fortune-cards`.
class HomeFortuneCardEntity {
  const HomeFortuneCardEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.icon,
    this.imageUrl,
    this.routePath,
    this.description,
    this.jetonCost,
    this.accent = const Color(0xFFB832FF),
  });

  factory HomeFortuneCardEntity.fromJson(Map<String, dynamic> json) {
    final href = _str(json, const ['href', 'url', 'link']) ?? '';
    var slug = _str(json, const ['slug', 'fortuneSlug']) ?? '';
    if (slug.isEmpty && href.contains('/')) {
      slug = href.split('/').where((s) => s.isNotEmpty).last;
    }
    return HomeFortuneCardEntity(
      id: _str(json, const ['id']) ?? slug,
      title: _str(json, const ['name', 'title']) ?? '',
      slug: slug,
      icon: _str(json, const ['icon', 'emoji']) ?? '🔮',
      imageUrl: _str(json, const ['image', 'imageUrl', 'thumbnail', 'iconUrl']),
      routePath: href.isNotEmpty ? href : null,
      description: _str(json, const [
        'description',
        'descTr',
        'desc',
        'subtitle',
      ]),
      jetonCost: parseFortuneJetonPrice(json),
    );
  }

  final String id;
  final String title;
  final String slug;
  final String icon;
  final String? imageUrl;
  final String? routePath;
  final String? description;
  final int? jetonCost;
  final Color accent;

  String get navigationSlug {
    if (slug.isNotEmpty) return slug;
    final href = routePath ?? '';
    final parts = href.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return id;
    return parts.last;
  }

  static String? _str(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}
