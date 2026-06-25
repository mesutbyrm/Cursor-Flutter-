import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/native_site_routes.dart';
import '../../../../../core/navigation/wallet_navigation.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../shell/presentation/widgets/branch_role_actions.dart';
import '../../widgets/premium/profile_glass.dart';
import 'profile_action_tile.dart';

/// 3 sütun premium hızlı işlemler grid'i.
class ProfileQuickActions extends ConsumerWidget {
  const ProfileQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teller = BranchRoleActions.tellerAction(ref);
    final agency = BranchRoleActions.agencyAction(ref);

    final items = <({IconData icon, String label, VoidCallback? onTap, List<Color>? g, Color? ic})>[
      (
        icon: Icons.videocam_rounded,
        label: 'Canlı Yayın Aç',
        onTap: () => context.push('/live/type'),
        g: [AppColors.liveRed.withValues(alpha: 0.7), const Color(0xFF2A0818)],
        ic: null,
      ),
      (
        icon: Icons.person_add_alt_1_rounded,
        label: 'Arkadaş Davet Et',
        onTap: () => context.push('/invite-friends'),
        g: [AppColors.accentPink.withValues(alpha: 0.5), const Color(0xFF1A1028)],
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
        icon: Icons.home_rounded,
        label: 'Ana Akış',
        onTap: () => context.go('/feed'),
        g: [AppColors.accentCyan.withValues(alpha: 0.4), const Color(0xFF0E1820)],
        ic: null,
      ),
      (
        icon: Icons.forum_rounded,
        label: 'Sosyal Akış',
        onTap: () => context.go('/social'),
        g: [const Color(0xFF1A2430), const Color(0xFF120C18)],
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
        icon: Icons.auto_awesome_rounded,
        label: 'Fal & Tarot',
        onTap: () => context.go('/fortune'),
        g: [const Color(0xFF312E81), const Color(0xFF12081F)],
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
        icon: teller.icon,
        label: teller.label.replaceAll('\n', ' '),
        onTap: () {
          if (teller.route != null) {
            teller.navigate(context);
          } else {
            openNativeSitePath(context, teller.nativePath ?? '/falci-ol');
          }
        },
        g: [const Color(0xFF3D2A10), const Color(0xFF1A1208)],
        ic: null,
      ),
      (
        icon: agency.icon,
        label: agency.label.replaceAll('\n', ' '),
        onTap: () {
          if (agency.route != null) {
            agency.navigate(context);
          } else {
            openNativeSitePath(context, agency.nativePath ?? '/ajans');
          }
        },
        g: [const Color(0xFF1A2838), const Color(0xFF0E141C)],
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
        icon: Icons.card_giftcard_rounded,
        label: 'Hediye Mağazası',
        onTap: () => context.push('/gifts/leaderboard'),
        g: [const Color(0xFF3A2010), const Color(0xFF1A1008)],
        ic: null,
      ),
      (
        icon: Icons.emoji_events_rounded,
        label: 'Görevler',
        onTap: () => context.push('/profile/growth'),
        g: [AppColors.accentPurple.withValues(alpha: 0.45), const Color(0xFF12081F)],
        ic: null,
      ),
      (
        icon: Icons.military_tech_rounded,
        label: 'Rozetler',
        onTap: () => context.push('/profile/growth'),
        g: [const Color(0xFF2A2040), const Color(0xFF100818)],
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
        const ProfileSectionTitle(title: 'Hızlı işlemler'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.88,
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
              delayMs: i * 25,
            );
          },
        ),
      ],
    );
  }
}
