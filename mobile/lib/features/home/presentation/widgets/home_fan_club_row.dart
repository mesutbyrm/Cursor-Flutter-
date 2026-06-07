import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/home_site_catalog.dart';
import '../theme/home_palette.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

class HomeFanClubRow extends StatelessWidget {
  const HomeFanClubRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeSectionHeader(
          title: 'Fan Club',
          leadingDotColor: const Color(0xFFFF4FD8),
          onTrailing: () => openNativeSitePath(context, '/fan-club'),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: HomeSiteCatalog.fanClubs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final club = HomeSiteCatalog.fanClubs[i];
              return _FanClubCard(
                item: club,
                onTap: () => openNativeSitePath(context, club.route),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FanClubCard extends StatelessWidget {
  const _FanClubCard({required this.item, required this.onTap});

  final HomeFanClubItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = item.memberCount;
    final memberLabel = members != null
        ? NumberFormat.compact(locale: 'tr').format(members)
        : null;

    return SizedBox(
      width: 140,
      child: HomeGlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF7B2FF7).withValues(alpha: 0.35),
            const Color(0xFF0A0618).withValues(alpha: 0.9),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(HomePalette.radiusCard),
                ),
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFF1A0E38),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.groups_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (memberLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: const Color(0xFFFF4FD8).withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          memberLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
