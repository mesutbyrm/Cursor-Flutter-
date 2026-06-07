import 'package:flutter/material.dart';

import '../../../../../core/navigation/native_site_routes.dart';
import '../../../domain/home_site_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Keşfet — 4 sütun grid.
class DiscoverSection extends StatelessWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeSectionTitle(emoji: '🧭', title: 'Keşfet'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
            ),
            itemCount: HomeSiteCatalog.discoverTiles.length,
            itemBuilder: (_, i) {
              final tile = HomeSiteCatalog.discoverTiles[i];
              return _Tile(
                icon: tile.icon,
                label: tile.label,
                gradient: tile.gradient,
                onTap: () => openNativeSitePath(context, tile.route),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(color: HomeApprovedDesign.border),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradient.first.withValues(alpha: 0.35),
              HomeApprovedDesign.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: gradient.first),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: HomeApprovedDesign.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
