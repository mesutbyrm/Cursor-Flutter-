import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/live_broadcast_prep_args.dart';

/// Yayın türü seçimi — fal kategorileri + sohbet/müzik.
class LiveBroadcastTypePage extends StatelessWidget {
  const LiveBroadcastTypePage({super.key});

  static const _fortuneTypes = [
    ('Kahve Falı', Icons.coffee_rounded),
    ('Tarot Falı', Icons.style_rounded),
    ('Burç Yorumu', Icons.star_rounded),
    ('El Falı', Icons.back_hand_rounded),
    ('Rüya Yorumu', Icons.nightlight_round),
    ('Aşk Falı', Icons.favorite_rounded),
    ('Katina Falı', Icons.auto_awesome_rounded),
    ('Numeroloji', Icons.pin_rounded),
  ];

  static const _otherTypes = [
    ('Sohbet', Icons.chat_bubble_rounded),
    ('Müzik', Icons.music_note_rounded),
    ('Muhabbet', Icons.theater_comedy_rounded),
    ('Eğlence', Icons.celebration_rounded),
    ('Oyun', Icons.sports_esports_rounded),
    ('Fitness', Icons.fitness_center_rounded),
  ];

  void _select(BuildContext context, String category, IconData icon, {bool fortune = false}) {
    context.push(
      '/live/prep',
      extra: LiveBroadcastPrepArgs(
        category: category,
        icon: icon,
        isFortune: fortune,
        subtitle: fortune ? 'Canlı fal yayını' : 'Canlı yayın',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0614),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: top + 8)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _CircleBack(onTap: () => context.pop()),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Yayın Türü Seçin',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hangi tür yayın yapacaksınız?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD8B4FE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: _SectionHeader(icon: Icons.auto_awesome_rounded, title: 'FAL TÜRLERİ'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = _fortuneTypes[i];
                  return _TypeOrb(
                    label: item.$1,
                    icon: item.$2,
                    onTap: () => _select(context, item.$1, item.$2, fortune: true),
                  );
                },
                childCount: _fortuneTypes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _SectionHeader(icon: Icons.grid_view_rounded, title: 'DİĞER KATEGORİLER'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = _otherTypes[i];
                  return _TypeOrb(
                    label: item.$1,
                    icon: item.$2,
                    large: true,
                    onTap: () => _select(context, item.$1, item.$2),
                  );
                },
                childCount: _otherTypes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A1548),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB832FF), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.1,
              color: Color(0xFFB832FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeOrb extends StatelessWidget {
  const _TypeOrb({
    required this.label,
    required this.icon,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 58.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B21B6), Color(0xFF312E81)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB832FF).withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: large ? 30 : 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
