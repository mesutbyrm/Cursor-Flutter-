import 'package:flutter/material.dart';

import '../../../../../core/navigation/native_site_routes.dart';
import '../../../domain/home_site_catalog.dart';
import '../../data/section_visual_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';
import '../premium_2026/premium_home_glass_card.dart';

/// Keşfet — 2026 premium yatay cam kart satırı.
class DiscoverSection extends StatelessWidget {
  const DiscoverSection({super.key});

  static const _cardW = 148.0;
  static const _cardH = 200.0;
  static const _gap = 12.0;

  static const _subtitles = <String, String>{
    'trends': 'Kısa videolar ve trendler',
    'invite': 'Arkadaşlarını davet et',
    'gifts': 'Hediye koleksiyonun',
  };

  @override
  Widget build(BuildContext context) {
    final tiles = HomeSiteCatalog.discoverTiles;
    return Column(
      children: [
        const HomeSectionTitle(emoji: '🧭', title: 'Keşfet'),
        SizedBox(
          height: _cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: _cardW * 2,
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              final tile = tiles[i];
              return PremiumHomeGlassCard(
                title: tile.label,
                subtitle: _subtitles[tile.id],
                imageUrl: SectionVisualCatalog.discoverTile(tile.id),
                heroTag: 'home-discover-${tile.id}',
                width: _cardW,
                height: _cardH,
                accentColor: tile.gradient.first,
                onTap: () => openNativeSitePath(context, tile.route),
              );
            },
          ),
        ),
      ],
    );
  }
}
