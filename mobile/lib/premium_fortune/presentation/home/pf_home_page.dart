import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pf_theme.dart';
import '../widgets/pf_glass_card.dart';
import '../widgets/pf_section_header.dart';

class PfHomePage extends ConsumerWidget {
  const PfHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = [
      _Module(
        title: 'Kahve Falı',
        subtitle: 'AI ile fincan analizi',
        icon: Icons.coffee_rounded,
        gradient: const [Color(0xFF6B3E26), Color(0xFF3D2317)],
        route: '/premium/coffee',
        cost: '15 kredi',
      ),
      _Module(
        title: 'Tarot',
        subtitle: 'Günlük & haftalık kartlar',
        icon: Icons.style_rounded,
        gradient: const [Color(0xFF4A2C82), Color(0xFF2A1650)],
        route: '/premium/tarot',
        cost: '20 kredi',
      ),
      _Module(
        title: 'Canlı Falcı',
        subtitle: 'Sesli & görüntülü görüşme',
        icon: Icons.mic_rounded,
        gradient: const [Color(0xFF1E5F74), Color(0xFF0D3340)],
        route: '/premium/live',
        cost: 'dk başı',
      ),
      _Module(
        title: 'Astroloji',
        subtitle: 'Burç & doğum haritası',
        icon: Icons.nightlight_round,
        gradient: const [Color(0xFF2D3A6B), Color(0xFF151B35)],
        route: '/premium/astrology',
      ),
      _Module(
        title: 'Rüya Tabiri',
        subtitle: 'AI rüya yorumu',
        icon: Icons.bedtime_rounded,
        gradient: const [Color(0xFF3B2F6B), Color(0xFF1E1838)],
        route: '/premium/dreams',
        cost: '10 kredi',
      ),
      _Module(
        title: 'Oyunlar',
        subtitle: 'Görevler, çark, rozetler',
        icon: Icons.casino_rounded,
        gradient: const [Color(0xFF6B2D5C), Color(0xFF3A1830)],
        route: '/premium/games',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PfGlassCard(
            padding: const EdgeInsets.all(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1650), Color(0xFF1A0E38)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [PfTheme.gold, PfTheme.pink],
                  ).createShader(bounds),
                  child: Text(
                    'Mistik Yolculuğunuz',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium AI fal deneyimi — kahve, tarot, astroloji ve canlı falcılar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
        const PfSectionHeader(
          title: 'Fal Türleri',
          subtitle: 'Yapay zeka destekli yorumlar',
        ),
        ...modules.map(
          (m) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: PfGlassCard(
              onTap: () => context.push(m.route),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: m.gradient),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(m.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.subtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (m.cost != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PfTheme.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PfTheme.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        m.cost!,
                        style: const TextStyle(
                          color: PfTheme.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Module {
  const _Module({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    this.cost,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String route;
  final String? cost;
}
