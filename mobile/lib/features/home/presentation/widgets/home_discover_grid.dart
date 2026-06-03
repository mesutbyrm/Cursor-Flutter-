import 'package:flutter/material.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/home_site_catalog.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

/// Keşfet — 2×4 neon grid (canlifal.com).
class HomeDiscoverGrid extends StatelessWidget {
  const HomeDiscoverGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeSectionHeader(
          title: 'Keşfet',
          leadingDotColor: Color(0xFF25F4EE),
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
              childAspectRatio: 0.82,
            ),
            itemCount: HomeSiteCatalog.discoverTiles.length,
            itemBuilder: (_, i) {
              final tile = HomeSiteCatalog.discoverTiles[i];
              return _DiscoverTile(tile: tile);
            },
          ),
        ),
      ],
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({required this.tile});

  final HomeDiscoverTile tile;

  @override
  Widget build(BuildContext context) {
    return HomeGlassCard(
      onTap: () => openNativeSitePath(context, tile.route),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: tile.gradient,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tile.icon, color: Colors.white, size: 26),
          const SizedBox(height: 8),
          Text(
            tile.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
