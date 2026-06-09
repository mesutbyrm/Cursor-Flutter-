import 'package:flutter/material.dart';

/// Ana sayfa fal vitrin kartı — `GET /api/homepage-fortune-cards`.
class HomeFortuneCardEntity {
  const HomeFortuneCardEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.icon,
    this.imageUrl,
    this.routePath,
    this.accent = const Color(0xFFB832FF),
  });

  final String id;
  final String title;
  final String slug;
  final String icon;
  final String? imageUrl;
  final String? routePath;
  final Color accent;

  String get navigationSlug {
    if (slug.isNotEmpty) return slug;
    final href = routePath ?? '';
    final parts = href.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return id;
    return parts.last;
  }
}
