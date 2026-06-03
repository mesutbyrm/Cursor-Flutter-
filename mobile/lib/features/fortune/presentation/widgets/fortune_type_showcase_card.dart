import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/fortune_type_showcase.dart';

/// Mockup vitrin kartı — AI illüstrasyon, açıklama, 3 özellik, Falını Aç.
class FortuneTypeShowcaseCard extends StatelessWidget {
  const FortuneTypeShowcaseCard({
    super.key,
    required this.showcase,
    required this.onOpenFortune,
    this.compact = false,
    this.showCardHeader = true,
  });

  final FortuneTypeShowcase showcase;
  final VoidCallback onOpenFortune;
  final bool compact;
  final bool showCardHeader;

  @override
  Widget build(BuildContext context) {
    final accent = showcase.type.accent;
    final illHeight = compact ? 140.0 : 168.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
        boxShadow: AppThemeColors.glowShadow(accent, blur: 18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.12),
            const Color(0xFF0F0A1E),
            const Color(0xFF0A0118),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showCardHeader) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        showcase.numberedTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: compact ? 17 : 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.star_outline_rounded,
                      color: accent.withValues(alpha: 0.85),
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: illHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        showcase.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _FallbackIllustration(
                          emoji: showcase.type.emoji,
                          accent: accent,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              accent.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                showcase.type.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.onSurfaceVariant.withValues(alpha: 0.95),
                  fontSize: compact ? 12 : 13,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (var i = 0; i < showcase.features.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _FeatureTile(
                        feature: showcase.features[i],
                        accent: accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _OpenFortuneButton(
                accent: accent,
                onPressed: onOpenFortune,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.accent});

  final FortuneTypeFeature feature;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(feature.icon, size: 18, color: accent),
        ),
        const SizedBox(height: 6),
        Text(
          feature.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _OpenFortuneButton extends StatelessWidget {
  const _OpenFortuneButton({required this.accent, required this.onPressed});

  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                accent,
                Color.lerp(accent, const Color(0xFF5B21B6), 0.45)!,
              ],
            ),
            boxShadow: AppThemeColors.glowShadow(accent, blur: 14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Falını Aç',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
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

class _FallbackIllustration extends StatelessWidget {
  const _FallbackIllustration({required this.emoji, required this.accent});

  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 64)),
    );
  }
}
