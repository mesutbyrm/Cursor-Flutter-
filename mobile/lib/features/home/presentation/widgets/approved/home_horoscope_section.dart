import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../data/section_visual_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Web ana sayfa — günlük burç şeridi (12 burç).
class HomeHoroscopeSection extends StatelessWidget {
  const HomeHoroscopeSection({super.key});

  static const signs = <(String name, String glyph, Color primary, Color secondary)>[
    ('Koç', '♈', Color(0xFFE53935), Color(0xFFFF8A80)),
    ('Boğa', '♉', Color(0xFF43A047), Color(0xFFA5D6A7)),
    ('İkizler', '♊', Color(0xFF1E88E5), Color(0xFF90CAF9)),
    ('Yengeç', '♋', Color(0xFF8E24AA), Color(0xFFCE93D8)),
    ('Aslan', '♌', Color(0xFFF4511E), Color(0xFFFFAB91)),
    ('Başak', '♍', Color(0xFF6D4C41), Color(0xFFBCAAA4)),
    ('Terazi', '♎', Color(0xFFEC407A), Color(0xFFF48FB1)),
    ('Akrep', '♏', Color(0xFF5E35B1), Color(0xFFB39DDB)),
    ('Yay', '♐', Color(0xFF00897B), Color(0xFF80CBC4)),
    ('Oğlak', '♑', Color(0xFF546E7A), Color(0xFFB0BEC5)),
    ('Kova', '♒', Color(0xFF039BE5), Color(0xFF81D4FA)),
    ('Balık', '♓', Color(0xFF3949AB), Color(0xFF9FA8DA)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '⭐',
          title: 'Günlük Burç',
          actionLabel: 'Tümü >',
          onAction: () => context.push('/fortune/yildiz-haritasi'),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: signs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (name, glyph, primary, secondary) = signs[i];
              return _SignChip(
                name: name,
                glyph: glyph,
                primary: primary,
                secondary: secondary,
                imageUrl: SectionVisualCatalog.horoscopeFor(name),
                onTap: () => context.push('/fortune/yildiz-haritasi'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SignChip extends StatelessWidget {
  const _SignChip({
    required this.name,
    required this.glyph,
    required this.primary,
    required this.secondary,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String glyph;
  final Color primary;
  final Color secondary;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
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
                            Colors.transparent,
                            primary.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        glyph,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HomeApprovedDesign.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
