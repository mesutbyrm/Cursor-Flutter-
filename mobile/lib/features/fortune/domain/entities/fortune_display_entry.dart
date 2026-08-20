import 'package:flutter/material.dart';

/// Fal vitrin kartı — API veya katalog kaynağından birleşik görünüm.
class FortuneDisplayEntry {
  const FortuneDisplayEntry({
    required this.slug,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.jetonCost,
    this.accent = const Color(0xFFB832FF),
    this.emoji,
  });

  /// Route slug (`/fortune/{slug}`).
  final String slug;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int? jetonCost;
  final Color accent;
  final String? emoji;

  bool get hasPrice => jetonCost != null && jetonCost! > 0;
}
