import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../fortune/presentation/data/fortune_catalog.dart';
import 'discover_section_header.dart';

/// Keşfet önizlemesi — 14 fal türü; tam sayfa: `/fortune`.
class DiscoverFortuneTarot extends StatelessWidget {
  const DiscoverFortuneTarot({super.key});

  static final _preview = FortuneCatalog.types.take(10).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Fal & Tarot',
          actionLabel: 'Tümünü Gör',
          onAction: () => context.go('/fortune'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/fortune'),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  gradient: LinearGradient(
                    colors: [
                      AppThemeColors.accentPurple.withValues(alpha: 0.25),
                      context.colors.surfaceContainer.withValues(alpha: 0.9),
                    ],
                  ),
                  border: Border.all(
                    color: AppThemeColors.accentPink.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Text('🔮', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FortuneCatalog.tagline,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${FortuneCatalog.types.length}+ fal türü',
                            style: TextStyle(
                              color: context.colors.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const cols = 5;
              const spacing = 8.0;
              final cellW =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in _preview)
                    SizedBox(
                      width: cellW,
                      child: _FortunePreviewTile(
                        emoji: card.emoji,
                        title: card.title,
                        border: card.accent,
                        onTap: () => _open(context, card.slug),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, String slug) {
    context.push('/fortune/$slug');
  }
}

class _FortunePreviewTile extends StatelessWidget {
  const _FortunePreviewTile({
    required this.emoji,
    required this.title,
    required this.border,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: border.withValues(alpha: 0.55),
              width: 1.1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                border.withValues(alpha: 0.22),
                context.colors.surfaceContainer.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: 22)),
                SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
