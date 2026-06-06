import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';

class HomeBannerCarousel extends ConsumerStatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  ConsumerState<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(homeBannersProvider);

    return banners.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: PremiumSkeleton(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.all(Radius.circular(HomePalette.radiusCard)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            SizedBox(
              height: 210,
              child: PageView.builder(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: items.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BannerCard(banner: items[i]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: _index == i ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _index == i
                        ? HomePalette.primary
                        : context.colors.onSurfaceMuted.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final HomeBannerEntity banner;

  @override
  Widget build(BuildContext context) {
    final colors = banner.gradient
        .map((c) => Color(c | 0xFF000000))
        .toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(HomePalette.radiusCard),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.length >= 2
                ? colors
                : [HomePalette.primary, HomePalette.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: HomePalette.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
              Positioned(
                right: -12,
                bottom: -8,
                child: Opacity(
                  opacity: 0.85,
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl!,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      banner.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (banner.ctaLabel != null)
                    FilledButton.icon(
                      onPressed: () {
                        final route = banner.ctaRoute;
                        if (route != null && route.isNotEmpty) {
                          openNativeSitePath(context, route);
                        } else {
                          context.push('/fortune');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: HomePalette.primary,
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(banner.ctaLabel!),
                    ),
                  if (banner.quickActions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: banner.quickActions
                          .take(4)
                          .map(
                            (a) => ActionChip(
                              label: Text(a.label),
                              onPressed: () {
                                final route = a.route;
                                if (route != null) {
                                  openNativeSitePath(context, route);
                                }
                              },
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.14),
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          )
                          .toList(),
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
