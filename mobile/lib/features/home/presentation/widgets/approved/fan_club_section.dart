import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/navigation/native_site_routes.dart';
import '../../../domain/home_site_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Fan Club — yatay kartlar.
class FanClubSection extends StatelessWidget {
  const FanClubSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '💜',
          title: 'Fan Club',
          actionLabel: 'Tümünü Gör >',
          onAction: () => openNativeSitePath(context, '/fan-club'),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: HomeSiteCatalog.fanClubs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
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
    final memberLabel =
        members != null ? NumberFormat.compact(locale: 'tr').format(members) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(color: HomeApprovedDesign.border),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HomeApprovedDesign.purple.withValues(alpha: 0.28),
              HomeApprovedDesign.surface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(HomeApprovedDesign.cardRadius),
                ),
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: HomeApprovedDesign.border,
                        child: Icon(
                          Icons.groups_rounded,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: HomeApprovedDesign.textSecondary,
                      ),
                    ),
                  ],
                  if (memberLabel != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: HomeApprovedDesign.pink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          memberLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: HomeApprovedDesign.textSecondary,
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
