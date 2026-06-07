import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

class HomeAdvisorsRow extends ConsumerWidget {
  const HomeAdvisorsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisors = ref.watch(homeAdvisorsProvider);

    return advisors.when(
      loading: () => Column(
        children: [
          const HomeSectionHeader(
            title: 'Popüler Falcılar',
            subtitle: 'Çevrimiçi uzmanlar',
            leadingDotColor: HomePalette.primary,
          ),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: 100,
                height: 130,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final online = items.where((a) => a.isOnline).toList();
        final list = online.isNotEmpty ? online : items;
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionHeader(
              title: 'Popüler Falcılar',
              subtitle: 'Çevrimiçi uzmanlar',
              leadingDotColor: HomePalette.primary,
              onTrailing: () => context.push('/search'),
            ),
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length.clamp(0, 12),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _AdvisorCard(advisor: list[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({required this.advisor});

  final OnlineAdvisorEntity advisor;

  @override
  Widget build(BuildContext context) {
    final viewers = advisor.viewerCount;
    final viewerLabel = viewers >= 1000
        ? '${(viewers / 1000).toStringAsFixed(1)}K'
        : '$viewers';

    return SizedBox(
      width: 108,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [HomePalette.primary, HomePalette.secondary],
                  ),
                ),
                child: advisor.avatarUrl != null && advisor.avatarUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 38,
                        backgroundImage:
                            CachedNetworkImageProvider(advisor.avatarUrl!),
                      )
                    : UserAvatar(radius: 38),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3DFF6E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ONLINE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F0B1D),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      viewerLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            advisor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            advisor.category ?? 'Fal uzmanı',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: context.colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: HomePalette.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/messages'),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.call_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
