import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:flutter/material.dart';

import '../../../home/domain/entities/home_fortune_card_entity.dart';
import '../../../platform/data/models/fortune_request_type.dart';
import '../../domain/entities/fortune_display_entry.dart';
import 'fortune_catalog.dart';

/// API + katalog → vitrin kartı eşlemesi (backend sırası korunur).
abstract final class FortuneDisplayResolver {
  static String resolveRouteSlug(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return FortuneCatalog.bySlug(trimmed)?.slug ?? trimmed;
  }

  static List<FortuneDisplayEntry> fromHomeCards(List<HomeFortuneCardEntity> cards) {
    return cards
        .where((c) => c.title.trim().isNotEmpty)
        .map((c) {
          final slug = resolveRouteSlug(c.navigationSlug);
          final catalog = FortuneCatalog.bySlug(slug);
          final apiImage = c.imageUrl?.trim();
          final desc = c.description?.trim();
          return FortuneDisplayEntry(
            slug: slug,
            title: c.title.trim(),
            subtitle: desc != null && desc.isNotEmpty ? desc : null,
            imageUrl: apiImage != null && apiImage.isNotEmpty
                ? CanlifalImageUrls.resolve(apiImage)
                : null,
            jetonCost: c.jetonCost,
            accent: catalog?.accent ?? c.accent,
            emoji: _emojiFromIcon(c.icon) ?? catalog?.emoji,
          );
        })
        .where((e) => e.slug.isNotEmpty)
        .toList();
  }

  static List<FortuneDisplayEntry> fromRequestTypes(
    List<FortuneRequestType> types,
  ) {
    final active = types.where((t) => t.isActive && t.key.isNotEmpty).toList();
    final ordered = _preserveBackendOrder(active);
    return ordered.map((t) {
      final slug = resolveRouteSlug(t.key);
      final catalog = FortuneCatalog.bySlug(slug);
      return FortuneDisplayEntry(
        slug: slug,
        title: t.label,
        subtitle: t.description,
        imageUrl: t.imageUrl,
        jetonCost: t.jetonCost,
        accent: catalog?.accent ?? const Color(0xFFB832FF),
        emoji: catalog?.emoji,
      );
    }).toList();
  }

  static List<FortuneDisplayEntry> fromCatalog({bool includeDaily = false}) {
    final types = FortuneCatalog.types.where((t) {
      if (t.isDaily && !includeDaily) return false;
      return t.slug.isNotEmpty;
    });
    return types
        .map(
          (t) => FortuneDisplayEntry(
            slug: t.slug,
            title: t.title,
            subtitle: t.description,
            accent: t.accent,
            emoji: t.emoji,
          ),
        )
        .toList();
  }

  static List<FortuneRequestType> _preserveBackendOrder(
    List<FortuneRequestType> types,
  ) {
    final hasSort = types.any((t) => t.sortOrder > 0);
    if (!hasSort) return types;
    return [...types]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static String? _emojiFromIcon(String icon) {
    final trimmed = icon.trim();
    if (trimmed.isEmpty || trimmed.startsWith('http')) return null;
    return trimmed;
  }

  /// Test / parse yardımcısı — tek JSON öğesi.
  static FortuneDisplayEntry? entryFromRequestTypeJson(
    Map<String, dynamic> json,
  ) {
    final type = FortuneRequestType.fromJson(json);
    if (!type.isActive || type.key.isEmpty) return null;
    final entries = fromRequestTypes([type]);
    return entries.isEmpty ? null : entries.first;
  }

  static FortuneDisplayEntry? entryFromHomeCardJson(Map<String, dynamic> json) {
    final card = HomeFortuneCardEntity.fromJson(json);
    if (card.title.trim().isEmpty) return null;
    final entries = fromHomeCards([card]);
    return entries.isEmpty ? null : entries.first;
  }
}
