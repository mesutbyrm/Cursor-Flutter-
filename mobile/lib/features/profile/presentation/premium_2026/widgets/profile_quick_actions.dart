import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/wallet_navigation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/premium/profile_glass.dart';
import 'profile_action_tile.dart';

/// Öne çıkan uygulama kısayolları — ayarlarla çakışmayan, sade liste.
class ProfileQuickActions extends ConsumerWidget {
  const ProfileQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <({IconData icon, String label, VoidCallback onTap, List<Color>? g, Color? ic})>[
      (
        icon: Icons.videocam_rounded,
        label: 'Canlı Yayın',
        onTap: () => context.push('/live/type'),
        g: [AppColors.liveRed.withValues(alpha: 0.7), const Color(0xFF2A0818)],
        ic: null,
      ),
      (
        icon: Icons.graphic_eq_rounded,
        label: 'Sesli Odalar',
        onTap: () => context.push('/voice-rooms'),
        g: [const Color(0xFF1E2A38), const Color(0xFF101820)],
        ic: null,
      ),
      (
        icon: Icons.psychology_alt_rounded,
        label: 'Canlı Falcılar',
        onTap: () => context.push('/canli-falcilar'),
        g: [const Color(0xFF4A1942), const Color(0xFF1A0818)],
        ic: null,
      ),
      (
        icon: Icons.auto_awesome_rounded,
        label: 'Fal & Tarot',
        onTap: () => context.go('/fortune'),
        g: [const Color(0xFF312E81), const Color(0xFF12081F)],
        ic: null,
      ),
      (
        icon: Icons.video_library_rounded,
        label: 'Video Yükle',
        onTap: () => context.push('/shorts/upload'),
        g: [AppColors.accentPurple.withValues(alpha: 0.5), const Color(0xFF1A1030)],
        ic: null,
      ),
      (
        icon: Icons.monetization_on_rounded,
        label: 'Jeton Yükle',
        onTap: () => openJetonStore(context, ref: ref),
        g: [const Color(0xFF5C4020), const Color(0xFF2A1C10)],
        ic: const Color(0xFFFFD54F),
      ),
      (
        icon: Icons.card_giftcard_rounded,
        label: 'Hediye Mağazası',
        onTap: () => context.push('/gifts/leaderboard'),
        g: [const Color(0xFF3A2010), const Color(0xFF1A1008)],
        ic: null,
      ),
      (
        icon: Icons.person_add_alt_1_rounded,
        label: 'Arkadaş Davet',
        onTap: () => context.push('/invite-friends'),
        g: [AppColors.accentPink.withValues(alpha: 0.5), const Color(0xFF1A1028)],
        ic: null,
      ),
      (
        icon: Icons.celebration_rounded,
        label: 'Etkinlikler',
        onTap: () => context.push('/games'),
        g: [const Color(0xFF203050), const Color(0xFF101820)],
        ic: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Hızlı erişim'),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.hardEdge,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ProfileActionTile(
                icon: item.icon,
                label: item.label,
                onTap: item.onTap,
                gradient: item.g,
                iconColor: item.ic,
              );
            },
          ),
        ),
      ],
    );
  }
}
