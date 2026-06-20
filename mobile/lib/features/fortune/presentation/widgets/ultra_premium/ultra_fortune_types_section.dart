import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/fortune_catalog.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../premium_2026/cinematic_fortune_grid_card.dart';
import '../premium_2026/premium_section_header.dart';
import 'ultra_fortune_tokens.dart';

/// Ultra hub fal türleri — 2 kolon sinematik grid.
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
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'FAL TÜRLERİ',
                  icon: Icons.grid_view_rounded,
                ),
              ),
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
                child: CinematicFortuneGridCard(
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
