import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/fortune_catalog.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../fortune_type_network_image.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Ultra hub fal türleri — 2 satır premium kartlar.
abstract final class UltraFortuneHubCatalog {
  static const entries = <({String slug, String subtitle, String? displayTitle})>[
    (slug: 'tarot', subtitle: 'Kartların mesajını keşfet', displayTitle: null),
    (slug: 'kahve-fali', subtitle: 'Fincandaki işaretleri çöz', displayTitle: null),
    (slug: 'ask-fali', subtitle: 'Kalbinin sesini dinle', displayTitle: null),
    (slug: 'yildiz-haritasi', subtitle: 'Gökyüzü rehberin', displayTitle: 'Yıldızname'),
    (slug: 'melek-kartlari', subtitle: 'Meleklerden rehberlik al', displayTitle: null),
    (slug: 'numeroloji', subtitle: 'Sayıların enerjisini öğren', displayTitle: null),
    (slug: 'pendul', subtitle: 'Kalbini dinle, rehberlik al', displayTitle: 'İstihare'),
    (slug: 'runik', subtitle: 'Aura ve enerji okuması', displayTitle: 'Aura'),
  ];

  static List<({FortuneTypeEntity type, String subtitle, String title})> get items {
    final out = <({FortuneTypeEntity type, String subtitle, String title})>[];
    for (final e in entries) {
      final type = FortuneCatalog.bySlug(e.slug);
      if (type != null) {
        out.add((
          type: type,
          subtitle: e.subtitle,
          title: e.displayTitle ?? type.title,
        ));
      }
    }
    return out;
  }
}

/// FAL TÜRLERİ bölümü — stagger giriş animasyonu.
class UltraFortuneTypesSection extends StatefulWidget {
  const UltraFortuneTypesSection({super.key});

  @override
  State<UltraFortuneTypesSection> createState() => _UltraFortuneTypesSectionState();
}

class _UltraFortuneTypesSectionState extends State<UltraFortuneTypesSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = UltraFortuneHubCatalog.items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) =>
                    UltraFortuneTokens.goldTypography.createShader(bounds),
                child: const Text(
                  'FAL TÜRLERİ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('✨', style: TextStyle(fontSize: 14)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/fortune/types'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Tüm Fal Türleri >',
                  style: TextStyle(
                    color: UltraFortuneTokens.softLilac.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final delay = index * 0.08;
              final anim = CurvedAnimation(
                parent: _stagger,
                curve: Interval(delay.clamp(0.0, 0.85), 1.0, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: anim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, 24 * (1 - anim.value)),
                  child: Opacity(opacity: anim.value, child: child),
                ),
                child: _PremiumTypeCard(
                  type: item.type,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: () => context.push('/fortune/${item.type.slug}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PremiumTypeCard extends StatelessWidget {
  const _PremiumTypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final FortuneTypeEntity type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(UltraFortuneTokens.cardRadius),
      blur: 40,
      elevated: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UltraFortuneTokens.cardRadius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FortuneTypeNetworkImage(
              slug: type.slug,
              accent: type.accent,
              emoji: type.emoji,
              borderRadius: 0,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    type.accent.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(type.emoji, style: const TextStyle(fontSize: 16)),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
