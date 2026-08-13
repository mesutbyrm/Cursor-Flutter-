import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../domain/entities/home_broadcast_image_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Yayın arka planları — `GET /api/broadcast-images`.
class HomeBroadcastImagesSection extends ConsumerWidget {
  const HomeBroadcastImagesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(homeBroadcastImagesProvider);
    return images.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '🎬',
              title: 'Yayın Arka Planları',
              actionLabel: 'Yayın Aç >',
              onAction: () => context.push('/live/prep'),
            ),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _ImageCard(
                  image: items[i],
                  onTap: () => context.push('/live/prep'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image, required this.onTap});

  final HomeBroadcastImageEntity image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          child: Stack(
            children: [
              CanlifalNetworkImage(
                url: image.imageUrl,
                width: 140,
                height: 100,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (image.title?.trim().isNotEmpty == true)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    image.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
