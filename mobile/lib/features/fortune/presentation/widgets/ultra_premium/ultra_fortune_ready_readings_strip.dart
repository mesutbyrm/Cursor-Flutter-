import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/fortune_ready_readings_data.dart';
import '../premium_2026/fortune_premium_card.dart';
import '../premium_2026/premium_section_header.dart';
import '../../data/fortune_catalog.dart';
import 'ultra_fortune_tokens.dart';

/// Hazır yorumlar mini şerit.
class UltraFortuneReadyReadingsStrip extends StatelessWidget {
  const UltraFortuneReadyReadingsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    const items = fortuneReadyReadingItems;
    const cardH = 132.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'HAZIR YORUMLAR',
                  icon: Icons.menu_book_rounded,
                  iconColor: UltraFortuneTokens.metallicGold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/fortune/ready'),
                child: Text(
                  'Tümü >',
                  style: TextStyle(
                    color: UltraFortuneTokens.softLilac.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = items[i];
                final type = FortuneCatalog.bySlug(item.slug);
                final accent = type?.accent ?? UltraFortuneTokens.electricPurple;
                return SizedBox(
                  width: 148,
                  child: FortunePremiumCard(
                    slug: item.slug,
                    title: item.title.split(' ').first,
                    subtitle: item.body,
                    accent: accent,
                    compact: true,
                    showEmojiInTitle: false,
                    width: 148,
                    height: cardH,
                    onTap: () => context.push('/fortune/ready'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
