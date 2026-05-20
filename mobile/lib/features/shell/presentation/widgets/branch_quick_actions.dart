import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';

/// Sosyal sekmesi — davet, jeton, akış ve sesli odalar.
class SocialBranchQuickActions extends StatelessWidget {
  const SocialBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickActionsSection(
      sectionIcon: Icons.bolt_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppTheme.accentSecondary,
      rows: [
        [
          QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Arkadaşlarını\ndavet et',
            gradient: [
              AppTheme.accent.withValues(alpha: 0.45),
              AppTheme.accentSecondary.withValues(alpha: 0.3),
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
              AppTheme.accentSecondary.withValues(alpha: 0.35),
              AppTheme.accent.withValues(alpha: 0.22),
            ],
            onTap: () => context.go('/feed'),
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
      accent: AppTheme.accentSecondary,
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
              AppTheme.accent.withValues(alpha: 0.45),
              AppTheme.accentSecondary.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
        ],
        [
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
              AppTheme.accentSecondary.withValues(alpha: 0.32),
              AppTheme.accent.withValues(alpha: 0.2),
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
      accent: AppTheme.accent,
      rows: [
        [
          QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Arkadaşlarını\ndavet et',
            gradient: [
              AppTheme.accent.withValues(alpha: 0.45),
              AppTheme.accentSecondary.withValues(alpha: 0.3),
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
              AppTheme.accentSecondary.withValues(alpha: 0.35),
              AppTheme.accent.withValues(alpha: 0.22),
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
      accent: AppTheme.accent,
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
              AppTheme.accent.withValues(alpha: 0.45),
              AppTheme.accentSecondary.withValues(alpha: 0.3),
            ],
            onTap: () => context.push('/invite-friends'),
          ),
        ],
        [
          QuickActionTile(
            icon: Icons.home_rounded,
            label: 'Ana\nakış',
            gradient: [
              AppTheme.accentSecondary.withValues(alpha: 0.35),
              AppTheme.accent.withValues(alpha: 0.22),
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
            icon: Icons.chat_bubble_rounded,
            label: 'Mesaj\nlar',
            gradient: [
              const Color(0xFF243040).withValues(alpha: 0.95),
              const Color(0xFF101820).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/messages'),
          ),
        ],
      ],
    );
  }
}

/// Profil sekmesi — kısayollar.
class ProfileBranchQuickActions extends StatelessWidget {
  const ProfileBranchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return QuickActionsSection(
      sectionIcon: Icons.bolt_rounded,
      sectionTitle: 'Hızlı işlemler',
      accent: AppTheme.accentSecondary,
      rows: [
        [
          QuickActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Arkadaşlarını\ndavet et',
            gradient: [
              AppTheme.accent.withValues(alpha: 0.45),
              AppTheme.accentSecondary.withValues(alpha: 0.3),
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
              AppTheme.accentSecondary.withValues(alpha: 0.35),
              AppTheme.accent.withValues(alpha: 0.22),
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
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Mesaj\nlar',
            gradient: [
              const Color(0xFF243040).withValues(alpha: 0.95),
              const Color(0xFF101820).withValues(alpha: 0.95),
            ],
            onTap: () => context.go('/messages'),
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
      ],
    );
  }
}
