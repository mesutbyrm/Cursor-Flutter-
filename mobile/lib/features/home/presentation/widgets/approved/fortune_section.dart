import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../../../fortune/presentation/widgets/fortune_type_cover_image.dart';
import '../../../domain/entities/home_fortune_card_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';
import '../premium_2026/home_horizontal_list.dart';
import '../premium_2026/home_section_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';

/// Fal & Tarot vitrini — API + katalog (14+ tür), bağımsız yükleme/hata.
class FortuneSection extends ConsumerWidget {
  const FortuneSection({super.key});

  static const _homeSlugs = [
    'tarot',
    'kahve-fali',
    'el-fali',
    'ruya-tabiri',
    'yildiz-haritasi',
    'ask-fali',
    'katina',
    'numeroloji',
    'melek-kartlari',
    'iskambil',
    'pendul',
    'runik',
    'evet-hayir',
    'cin-fali',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(homeFortuneCardsProvider);

    return api.when(
      loading: () => HomeSectionShell(
        emoji: '🔮',
        title: 'Fal & Tarot',
        actionLabel: 'Tümü >',
        onAction: () => context.go('/fortune'),
        contentHeight: HomeApprovedDesign.fortuneCardH + 8,
        loading: HomeHorizontalList(
          height: HomeApprovedDesign.fortuneCardH,
          itemCount: 5,
          itemBuilder: (_, _) => const PremiumSkeleton(
            width: HomeApprovedDesign.fortuneCardW,
            height: HomeApprovedDesign.fortuneCardH,
            borderRadius: BorderRadius.all(
              Radius.circular(HomeApprovedDesign.cardRadius),
            ),
          ),
        ),
      ),
      error: (e, _) => HomeSectionShell(
        emoji: '🔮',
        title: 'Fal & Tarot',
        actionLabel: 'Tümü >',
        onAction: () => context.go('/fortune'),
        errorMessage: 'Fal kartları yüklenemedi',
        onRetry: () => ref.invalidate(homeFortuneCardsProvider),
      ),
      data: (cards) {
        final entries =
            cards.isNotEmpty ? _fromApi(cards) : _fromCatalog();
        if (entries.isEmpty) {
          return HomeSectionShell(
            emoji: '🔮',
            title: 'Fal & Tarot',
            actionLabel: 'Tümü >',
            onAction: () => context.go('/fortune'),
            emptyIcon: Icons.auto_awesome_rounded,
            emptyMessage: 'Fal türleri şu an listelenemiyor',
          );
        }
        return HomeSectionShell(
          emoji: '🔮',
          title: 'Fal & Tarot',
          actionLabel: 'Tümü >',
          onAction: () => context.go('/fortune'),
          child: HomeHorizontalList(
            height: HomeApprovedDesign.fortuneCardH,
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              return _FortuneCard(
                title: e.title,
                subtitle: e.subtitle,
                accent: e.accent,
                slug: e.slug,
                imageUrl: e.imageUrl,
                onTap: () => context.push('/fortune/${e.slug}'),
              );
            },
          ),
        );
      },
    );
  }

  List<
      ({
        String slug,
        String title,
        String? subtitle,
        Color accent,
        String? imageUrl,
      })> _fromApi(List<HomeFortuneCardEntity> cards) {
    return cards.take(14).map((c) {
      final slug = FortuneCatalog.bySlug(c.navigationSlug)?.slug ??
          c.navigationSlug;
      final catalog = FortuneCatalog.bySlug(slug);
      final apiImage = c.imageUrl?.trim();
      return (
        slug: slug,
        title: c.title,
        subtitle: catalog?.description,
        accent: catalog?.accent ?? c.accent,
        imageUrl: apiImage != null && apiImage.isNotEmpty
            ? CanlifalImageUrls.resolve(apiImage)
            : null,
      );
    }).toList();
  }

  List<
      ({
        String slug,
        String title,
        String? subtitle,
        Color accent,
        String? imageUrl,
      })> _fromCatalog() {
    final out = <
        ({
          String slug,
          String title,
          String? subtitle,
          Color accent,
          String? imageUrl,
        })>[];
    for (final slug in _homeSlugs) {
      final type = FortuneCatalog.bySlug(slug);
      if (type != null) {
        out.add((
          slug: type.slug,
          title: type.title,
          subtitle: type.description,
          accent: type.accent,
          imageUrl: null,
        ));
      }
    }
    return out;
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({
    required this.title,
    required this.accent,
    required this.slug,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
  });

  final String title;
  final String? subtitle;
  final Color accent;
  final String slug;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Ink(
          width: HomeApprovedDesign.fortuneCardW + 12,
          height: HomeApprovedDesign.fortuneCardH,
          decoration: HomePremiumDesign.glassCard(
            tint: HomePremiumDesign.surface,
            radius: HomeApprovedDesign.cardRadius,
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            child: Stack(
            fit: StackFit.expand,
            children: [
              FortuneTypeCoverImage(
                slug: slug,
                accent: accent,
                imageWidth: 480,
                networkUrlOverride: imageUrl,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
