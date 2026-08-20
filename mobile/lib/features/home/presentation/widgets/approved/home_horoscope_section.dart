import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../data/section_visual_catalog.dart';
import '../../../domain/home_zodiac_signs.dart';
import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';
import '../home_horoscope_daily_sheet.dart';
import 'home_section_title.dart';
import '../premium_2026/home_horizontal_list.dart';

/// Web ana sayfa — günlük burç şeridi (12 burç).
class HomeHoroscopeSection extends ConsumerWidget {
  const HomeHoroscopeSection({super.key});

  static const signs =
      <(String name, String glyph, Color primary, Color secondary)>[
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

  static String? _matchUserSign(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    for (final (name, _, _, _) in signs) {
      if (name.toLowerCase() == value) return name;
      if (HomeZodiacSigns.apiValueFor(name) == value) return name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSign = ref.watch(profileExtendedProvider).valueOrNull?.zodiacSign;
    final highlighted = _matchUserSign(userSign);

    final ordered = [...signs];
    if (highlighted != null) {
      ordered.sort((a, b) {
        if (a.$1 == highlighted) return -1;
        if (b.$1 == highlighted) return 1;
        return 0;
      });
    }

    return Column(
      children: [
        HomeSectionTitle(
          emoji: '⭐',
          title: 'Günlük Burç',
          actionLabel: 'Tümü >',
          onAction: () => context.push('/fortune/yildiz-haritasi'),
        ),
        HomeHorizontalList(
          height: 108,
          itemCount: ordered.length,
          itemBuilder: (context, i) {
            final (name, glyph, primary, secondary) = ordered[i];
            final isMine = highlighted != null && name == highlighted;
            return _SignChip(
              name: name,
              glyph: glyph,
              primary: primary,
              secondary: secondary,
              imageUrl: SectionVisualCatalog.horoscopeFor(name),
              highlighted: isMine,
              onTap: () => showHomeHoroscopeDailySheet(
                context,
                ref,
                signName: name,
                glyph: glyph,
              ),
            );
          },
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
    this.highlighted = false,
  });

  final String name;
  final String glyph;
  final Color primary;
  final Color secondary;
  final String imageUrl;
  final VoidCallback onTap;
  final bool highlighted;

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
                    color: highlighted
                        ? HomePremiumDesign.accent
                        : primary.withValues(alpha: 0.55),
                    width: highlighted ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (highlighted ? HomePremiumDesign.accent : primary)
                          .withValues(alpha: highlighted ? 0.45 : 0.35),
                      blurRadius: highlighted ? 14 : 10,
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
                highlighted ? '$name · Sen' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlighted
                      ? HomePremiumDesign.accent
                      : HomeApprovedDesign.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
