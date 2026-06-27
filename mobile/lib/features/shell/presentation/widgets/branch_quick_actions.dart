import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import 'branch_role_actions.dart';

/// Sosyal sekmesi — davet, jeton, akış ve sesli odalar.
class SocialBranchQuickActions extends StatelessWidget {
  const SocialBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickActionsSection(
      sectionIcon: Icons.bolt_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppColors.accentCyan,
      rows: [
        [
          QuickActionTile(
            icon: Icons.videocam_rounded,
            label: 'Canlı Yayın\nAç',
            gradient: [
              AppColors.liveRed.withValues(alpha: 0.55),
              AppColors.accentPink.withValues(alpha: 0.35),
            ],
            onTap: () => context.push('/live/type'),
          ),
          QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Arkadaşlarını\ndavet et',
            gradient: [
              AppColors.accentPink.withValues(alpha: 0.45),
              AppColors.accentCyan.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.monetization_on_rounded,
            label: 'Jeton\nyükle',
            gradient: [
              const Color(0xFF5C4020).withValues(alpha: 0.85),
              const Color(0xFF2A1C10).withValues(alpha: 0.9),
            ],
            onTap: () => context.push('/jeton-store'),
          ),
          QuickActionTile(
            icon: Icons.home_rounded,
            label: 'Ana\nakış',
            gradient: [
              AppColors.accentCyan.withValues(alpha: 0.35),
              AppColors.accentPink.withValues(alpha: 0.22),
            ],
            onTap: () => context.go('/feed'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.graphic_eq_rounded,
            label: 'Sesli\nodalar',
            gradient: [
              const Color(0xFF1E2A38).withValues(alpha: 0.95),
              const Color(0xFF101820).withValues(alpha: 0.95),
            ],
            onTap: () => context.push('/voice-rooms'),
          ),
        ],
      ],
    );
  }
}

/// Canlı → Yayınlar sekmesi üstü.
class LiveStreamsBranchQuickActions extends StatelessWidget {
  const LiveStreamsBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickActionsSection(
      sectionIcon: Icons.live_tv_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppColors.accentCyan,
      rows: [
        [
          QuickActionTile(
            icon: Icons.videocam_rounded,
            label: 'Canlı Yayın\nAç',
            gradient: [
              AppColors.liveRed.withValues(alpha: 0.55),
              AppColors.accentPink.withValues(alpha: 0.35),
            ],
            onTap: () => context.push('/live/type'),
          ),
          QuickActionTile(
            icon: Icons.monetization_on_rounded,
            label: 'Jeton\nyükle',
            gradient: [
              const Color(0xFF5C4020).withValues(alpha: 0.85),
              const Color(0xFF2A1C10).withValues(alpha: 0.9),
            ],
            onTap: () => context.push('/jeton-store'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.card_giftcard_rounded,
            label: 'Davet\npaylaş',
            gradient: [
              AppColors.accentPink.withValues(alpha: 0.45),
              AppColors.accentCyan.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
          QuickActionTile(
            icon: Icons.forum_rounded,
            label: 'Sosyal\nakış',
            gradient: [
              const Color(0xFF1A2430).withValues(alpha: 0.95),
              const Color(0xFF120C18).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/social'),
          ),
          QuickActionTile(
            icon: Icons.home_rounded,
            label: 'Hikâye\nakışı',
            gradient: [
              AppColors.accentCyan.withValues(alpha: 0.32),
              AppColors.accentPink.withValues(alpha: 0.2),
            ],
            onTap: () => context.go('/feed'),
          ),
        ],
      ],
    );
  }
}

/// Mesajlar listesi üstü.
class MessagesBranchQuickActions extends StatelessWidget {
  const MessagesBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickActionsSection(
      sectionIcon: Icons.chat_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppColors.accentPink,
      rows: [
        [
          QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Arkadaşlarını\ndavet et',
            gradient: [
              AppColors.accentPink.withValues(alpha: 0.45),
              AppColors.accentCyan.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
          QuickActionTile(
            icon: Icons.monetization_on_rounded,
            label: 'Jeton\nyükle',
            gradient: [
              const Color(0xFF5C4020).withValues(alpha: 0.85),
              const Color(0xFF2A1C10).withValues(alpha: 0.9),
            ],
            onTap: () => context.push('/jeton-store'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.headset_mic_rounded,
            label: 'Web\nsohbet',
            gradient: [
              const Color(0xFF243040).withValues(alpha: 0.95),
              const Color(0xFF101820).withValues(alpha: 0.95),
            ],
            onTap: () => context.push(
              CanlifalWebRoute.location(
                relativePath: '/sohbet',
                title: 'Sohbet',
              ),
            ),
          ),
          QuickActionTile(
            icon: Icons.home_rounded,
            label: 'Ana\nakış',
            gradient: [
              AppColors.accentCyan.withValues(alpha: 0.35),
              AppColors.accentPink.withValues(alpha: 0.22),
            ],
            onTap: () => context.go('/feed'),
          ),
        ],
      ],
    );
  }
}

/// Canlı → Sohbet (sesli odalar) sekmesi üstü.
class LiveVoiceBranchQuickActions extends StatelessWidget {
  const LiveVoiceBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickActionsSection(
      sectionIcon: Icons.headset_mic_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppColors.accentPink,
      rows: [
        [
          QuickActionTile(
            icon: Icons.monetization_on_rounded,
            label: 'Jeton\nyükle',
            gradient: [
              const Color(0xFF5C4020).withValues(alpha: 0.85),
              const Color(0xFF2A1C10).withValues(alpha: 0.9),
            ],
            onTap: () => context.push('/jeton-store'),
          ),
          QuickActionTile(
            icon: Icons.card_giftcard_rounded,
            label: 'Davet\npaylaş',
            gradient: [
              AppColors.accentPink.withValues(alpha: 0.45),
              AppColors.accentCyan.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.home_rounded,
            label: 'Ana\nakış',
            gradient: [
              AppColors.accentCyan.withValues(alpha: 0.35),
              AppColors.accentPink.withValues(alpha: 0.22),
            ],
            onTap: () => context.go('/feed'),
          ),
          QuickActionTile(
            icon: Icons.forum_rounded,
            label: 'Sosyal\nakış',
            gradient: [
              const Color(0xFF1A2430).withValues(alpha: 0.95),
              const Color(0xFF120C18).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/social'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.maps_home_work_outlined,
            label: 'Tüm\nodalar',
            gradient: [
              const Color(0xFF1E2A38).withValues(alpha: 0.95),
              const Color(0xFF101820).withValues(alpha: 0.95),
            ],
            onTap: () => context.push('/voice-rooms'),
          ),
          QuickActionTile(
            icon: Icons.auto_awesome_rounded,
            label: 'Fal&\nTarot',
            gradient: [
              AppColors.accentPurple.withValues(alpha: 0.5),
              const Color(0xFF312E81).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/fortune'),
          ),
        ],
      ],
    );
  }
}

/// Profil sekmesi — kısayollar.
class ProfileBranchQuickActions extends ConsumerWidget {
  const ProfileBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teller = BranchRoleActions.tellerAction(ref);
    final agency = BranchRoleActions.agencyAction(ref);
    return QuickActionsSection(
      sectionIcon: Icons.bolt_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppColors.accentCyan,
      rows: [
        [
          QuickActionTile(
            icon: Icons.videocam_rounded,
            label: 'Canlı Yayın\nAç',
            gradient: [
              AppColors.liveRed.withValues(alpha: 0.55),
              AppColors.accentPink.withValues(alpha: 0.35),
            ],
            onTap: () => context.push('/live/type'),
          ),
          QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Arkadaşlarını\ndavet et',
            gradient: [
              AppColors.accentPink.withValues(alpha: 0.45),
              AppColors.accentCyan.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
          QuickActionTile(
            icon: Icons.monetization_on_rounded,
            label: 'Jeton\nyükle',
            gradient: [
              const Color(0xFF5C4020).withValues(alpha: 0.85),
              const Color(0xFF2A1C10).withValues(alpha: 0.9),
            ],
            onTap: () => context.push('/jeton-store'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.home_rounded,
            label: 'Ana\nakış',
            gradient: [
              AppColors.accentCyan.withValues(alpha: 0.35),
              AppColors.accentPink.withValues(alpha: 0.22),
            ],
            onTap: () => context.go('/feed'),
          ),
          QuickActionTile(
            icon: Icons.forum_rounded,
            label: 'Sosyal\nakış',
            gradient: [
              const Color(0xFF1A2430).withValues(alpha: 0.95),
              const Color(0xFF120C18).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/social'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.video_library_rounded,
            label: 'Video\nyükle',
            gradient: [
              AppColors.accentPurple.withValues(alpha: 0.45),
              AppColors.accentPink.withValues(alpha: 0.28),
            ],
            onTap: () => context.push('/shorts/upload'),
          ),
          QuickActionTile(
            icon: Icons.auto_awesome_rounded,
            label: 'Fal&\nTarot',
            gradient: [
              AppColors.accentPurple.withValues(alpha: 0.5),
              const Color(0xFF312E81).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/fortune'),
          ),
          QuickActionTile(
            icon: Icons.graphic_eq_rounded,
            label: 'Sesli\nodalar',
            gradient: [
              const Color(0xFF1E2A38).withValues(alpha: 0.95),
              const Color(0xFF101820).withValues(alpha: 0.95),
            ],
            onTap: () => context.push('/voice-rooms'),
          ),
        ],
        [
          QuickActionTile(
            icon: teller.icon,
            label: teller.label,
            gradient: [
              const Color(0xFF3D2A10).withValues(alpha: 0.95),
              const Color(0xFF1A1208).withValues(alpha: 0.95),
            ],
            onTap: () {
              if (teller.route != null) {
                teller.navigate(context);
              } else {
                openNativeSitePath(context, teller.nativePath ?? '/falci-ol');
              }
            },
          ),
          QuickActionTile(
            icon: agency.icon,
            label: agency.label,
            gradient: [
              const Color(0xFF1A2838).withValues(alpha: 0.95),
              const Color(0xFF0E141C).withValues(alpha: 0.95),
            ],
            onTap: () {
              if (agency.route != null) {
                agency.navigate(context);
              } else {
                openNativeSitePath(context, agency.nativePath ?? '/ajans-ol');
              }
            },
          ),
        ],
      ],
    );
  }
}
