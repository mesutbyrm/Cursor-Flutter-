import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/fortune_display_entry.dart';
import '../data/fortune_display_resolver.dart';

/// Fal kartı navigasyonu — mevcut `/fortune/{slug}` rotası.
void openFortuneTypeDestination(
  BuildContext context,
  FortuneDisplayEntry entry,
) {
  final slug = FortuneDisplayResolver.resolveRouteSlug(entry.slug);
  if (slug.isEmpty) {
    context.push('/fortune/types');
    return;
  }
  context.push('/fortune/$slug');
}

/// Tüm fal türleri listesi.
void openFortuneTypesCatalog(BuildContext context) {
  context.push('/fortune/types');
}
