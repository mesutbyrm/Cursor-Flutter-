import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../fortune/presentation/data/fortune_catalog.dart';
import '../theme/home_palette.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

/// Fal & Tarot — 2×4 grid (canlifal.com).
class HomeFortuneGrid extends StatelessWidget {
  const HomeFortuneGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = FortuneCatalog.hubFortuneTypes;

    return Column(
      children: [
        HomeSectionHeader(
          title: 'Fal & Tarot',
          leadingDotColor: const Color(0xFFB84DFF),
          onTrailing: () => context.go('/fortune'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return _FortuneTile(
                emoji: e.type.emoji,
                title: e.type.title,
                accent: e.type.accent,
                onTap: () => context.push('/fortune/${e.type.slug}'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: HomeGlassCard(
            onTap: () => context.push('/fortune/types'),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+6 daha fazla fal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FortuneTile extends StatelessWidget {
  const _FortuneTile({
    required this.emoji,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      glowColor: accent,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.35),
          const Color(0xFF12082A).withValues(alpha: 0.85),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
