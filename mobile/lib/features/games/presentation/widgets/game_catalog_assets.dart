import 'package:flutter/material.dart';

import '../../domain/game_models.dart';

/// Oyun görseli önceliği: backend URL → asset → ikon fallback.
abstract final class GameCatalogAssets {
  static const violet = Color(0xFF8B5CF6);

  static String? imageUrl(GameCatalogItem game) {
    final url = game.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  static IconData iconFor(GameCatalogItem game) {
    final id = game.id.toLowerCase();
    if (id.contains('okey')) return Icons.view_module_rounded;
    if (id.contains('xox') || id.contains('tic')) return Icons.grid_3x3_rounded;
    if (id.contains('tombala') || id.contains('bingo')) {
      return Icons.grid_on_rounded;
    }
    if (id.contains('tavla') || id.contains('backgammon')) {
      return Icons.casino_rounded;
    }
    if (id.contains('pisti')) return Icons.style_rounded;
    if (id.contains('quiz')) return Icons.quiz_rounded;
    if (id.contains('wheel') || id.contains('cark')) {
      return Icons.attractions_rounded;
    }
    return game.icon;
  }

  static List<Color> gradientFor(GameCatalogItem game) {
    final id = game.id.toLowerCase();
    if (id.contains('okey')) {
      return const [Color(0xFF059669), Color(0xFF065F46)];
    }
    if (id.contains('xox')) {
      return const [Color(0xFF8B5CF6), Color(0xFF6366F1)];
    }
    if (id.contains('tombala')) {
      return const [Color(0xFFEC4899), Color(0xFFDB2777)];
    }
    if (id.contains('tavla')) {
      return const [Color(0xFFF59E0B), Color(0xFFD97706)];
    }
    if (id.contains('pisti')) {
      return const [Color(0xFF0EA5E9), Color(0xFF0284C7)];
    }
    return const [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  }
}
