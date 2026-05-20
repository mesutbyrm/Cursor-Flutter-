import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import 'discover_section_header.dart';

/// canlifal.com ana sayfadaki gibi 14 fal türü — satırda 5 kart.
class DiscoverFortuneTarot extends StatelessWidget {
  const DiscoverFortuneTarot({super.key});

  static const _cards = <_FortuneCard>[
    _FortuneCard(title: 'Tarot', subtitle: 'Kartların sırrı', border: Color(0xFFB832FF), emoji: '🃏', slug: 'tarot'),
    _FortuneCard(title: 'Aşk Falı', subtitle: 'Kalbinin sesi', border: Color(0xFFFF4EC8), emoji: '💜', slug: 'ask-fali'),
    _FortuneCard(title: 'Kahve Falı', subtitle: 'Fincan yorumu', border: Color(0xFFD97706), emoji: '☕', slug: 'kahve-fali'),
    _FortuneCard(title: 'Yıldız', subtitle: 'Burç haritası', border: Color(0xFF38BDF8), emoji: '✨', slug: 'yildiz-haritasi'),
    _FortuneCard(title: 'El Falı', subtitle: 'Çizgilerin dili', border: Color(0xFFF472B6), emoji: '🖐️', slug: 'el-fali'),
    _FortuneCard(title: 'Katina', subtitle: 'Aşk kartları', border: Color(0xFFA855F7), emoji: '🎴', slug: 'katina'),
    _FortuneCard(title: 'İskambil', subtitle: 'Klasik fal', border: Color(0xFF6366F1), emoji: '🂡', slug: 'iskambil'),
    _FortuneCard(title: 'Melek', subtitle: 'Melek kartları', border: Color(0xFF67E8F9), emoji: '👼', slug: 'melek-kartlari'),
    _FortuneCard(title: 'Numeroloji', subtitle: 'Sayıların gücü', border: Color(0xFF34D399), emoji: '🔢', slug: 'numeroloji'),
    _FortuneCard(title: 'Rüya', subtitle: 'Rüya tabiri', border: Color(0xFF818CF8), emoji: '🌙', slug: 'ruya-tabiri'),
    _FortuneCard(title: 'Çin Falı', subtitle: 'I-Ching', border: Color(0xFFEF4444), emoji: '🏮', slug: 'cin-fali'),
    _FortuneCard(title: 'Pendül', subtitle: 'Enerji dengesi', border: Color(0xFF14B8A6), emoji: '🔮', slug: 'pendul'),
    _FortuneCard(title: 'Runik', subtitle: 'Kadim semboller', border: Color(0xFF94A3B8), emoji: 'ᚠ', slug: 'runik'),
    _FortuneCard(title: 'Evet / Hayır', subtitle: 'Hızlı cevap', border: Color(0xFFFBBF24), emoji: '❓', slug: 'evet-hayir'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Fal & Tarot',
          actionLabel: 'Tüm Falcılar',
          onAction: () {
            context.push(
              CanlifalWebRoute.location(
                relativePath: '/fal',
                title: 'Fal & Tarot',
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const cols = 5;
              const spacing = 8.0;
              final cellW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in _cards)
                    SizedBox(
                      width: cellW,
                      child: _FortuneTile(
                        card: card,
                        onTap: () => _openFortune(context, card),
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

  void _openFortune(BuildContext context, _FortuneCard card) {
    if (Env.useNextAuth) {
      context.push(
        CanlifalWebRoute.location(
          relativePath: '/fal/${card.slug}',
          title: card.title,
        ),
      );
    }
  }
}

class _FortuneCard {
  const _FortuneCard({
    required this.title,
    required this.subtitle,
    required this.border,
    required this.emoji,
    required this.slug,
  });

  final String title;
  final String subtitle;
  final Color border;
  final String emoji;
  final String slug;
}

class _FortuneTile extends StatelessWidget {
  const _FortuneTile({required this.card, required this.onTap});

  final _FortuneCard card;
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
              color: card.border.withValues(alpha: 0.55),
              width: 1.1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                card.border.withValues(alpha: 0.22),
                AppColors.bgPurpleGlow.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  card.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textMuted,
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
