import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Web ana sayfa — günlük burç şeridi (12 burç).
class HomeHoroscopeSection extends StatelessWidget {
  const HomeHoroscopeSection({super.key});

  static const signs = [
    ('Koç', '♈'),
    ('Boğa', '♉'),
    ('İkizler', '♊'),
    ('Yengeç', '♋'),
    ('Aslan', '♌'),
    ('Başak', '♍'),
    ('Terazi', '♎'),
    ('Akrep', '♏'),
    ('Yay', '♐'),
    ('Oğlak', '♑'),
    ('Kova', '♒'),
    ('Balık', '♓'),
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
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: signs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (name, glyph) = signs[i];
              return _SignChip(
                name: name,
                glyph: glyph,
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
    required this.onTap,
  });

  final String name;
  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Ink(
          width: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HomeApprovedDesign.purple.withValues(alpha: 0.35),
                HomeApprovedDesign.surface,
              ],
            ),
            border: Border.all(
              color: HomeApprovedDesign.purple.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(glyph, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
