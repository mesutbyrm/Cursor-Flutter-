import 'package:flutter/material.dart';

import '../../../../../core/navigation/native_site_routes.dart';
import '../../../domain/home_site_catalog.dart';
import '../../data/section_visual_catalog.dart';
import '../../../../../core/images/canlifal_network_image.dart';
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
                imageUrl: SectionVisualCatalog.discoverTile(tile.id),
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
    required this.imageUrl,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: HomeApprovedDesign.border),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CanlifalNetworkImage(url: imageUrl, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
