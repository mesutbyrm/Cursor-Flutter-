import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_circular_orb.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

/// canlifal.com ana sayfa — **Canlı Falcılar** (yuvarlak avatarlar).
class HomeLiveFortuneTellersRow extends ConsumerWidget {
  const HomeLiveFortuneTellersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellers = ref.watch(homeLiveFortuneTellersProvider);

    return tellers.when(
      loading: () => Column(
        children: [
          const HomeSectionHeader(
            title: 'Canlı Falcılar',
            subtitle: 'Çevrimiçi uzmanlarla anında seans',
            leadingDotColor: AppThemeColors.accentPink,
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: 72,
                height: 72,
                borderRadius: BorderRadius.all(Radius.circular(36)),
              ),
            ),
          ),
        ],
      ),
      error: (e, _) => Column(
        children: [
          const HomeSectionHeader(
            title: 'Canlı Falcılar',
            subtitle: 'Liste yüklenemedi',
            leadingDotColor: AppThemeColors.accentPink,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$e',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final online = items.where((t) => t.isOnline).toList();
        final list = (online.isNotEmpty ? online : items).take(12).toList();
        return Column(
          children: [
            HomeSectionHeader(
              title: 'Canlı Falcılar',
              subtitle: 'Çevrimiçi uzmanlarla anında seans',
              leadingDotColor: AppThemeColors.accentPink,
              onTrailing: () => context.push('/canli-falcilar'),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => _TellerOrb(teller: list[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _QuickActions(),
            ),
          ],
        );
      },
    );
  }
}

class _TellerOrb extends StatelessWidget {
  const _TellerOrb({required this.teller});

  final LiveFortuneTellerEntity teller;

  @override
  Widget build(BuildContext context) {
    final subtitle = teller.rating > 0
        ? '★ ${teller.rating.toStringAsFixed(1)}'
        : teller.displayCategory;

    return HomeCircularOrb(
      title: teller.name,
      subtitle: subtitle,
      imageUrl: teller.avatarUrl,
      ringColor: teller.isOnline
          ? const Color(0xFF3DFF6E)
          : HomePalette.primary,
      badge: teller.isOnline ? const LiveBadge(compact: true) : null,
      onTap: () => context.push('/canli-falcilar/${teller.id}'),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.auto_awesome_rounded,
            label: 'Fal & Tarot',
            onTap: () => context.go('/fortune'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionChip(
            icon: Icons.mic_rounded,
            label: 'Sesli Sohbet',
            onTap: () => context.push('/voice-rooms'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionChip(
            icon: Icons.person_add_rounded,
            label: 'Falcı Ol',
            onTap: () => context.push('/content-hub'),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: HomePalette.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
