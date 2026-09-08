import 'package:flutter/material.dart';

import '../../../../core/site_animation/domain/site_animation_command.dart';
import '../../../../core/site_animation/domain/site_animation_tier.dart';
import '../../../../core/site_animation/domain/site_animation_type.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_entrance_card.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/admin_site_animation.dart';

class AdminSiteAnimationCard extends StatelessWidget {
  const AdminSiteAnimationCard({
    super.key,
    required this.animation,
    required this.onPreview,
    required this.onEdit,
    required this.onAssign,
    required this.onToggleActive,
  });

  final AdminSiteAnimation animation;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onToggleActive;

  Color get _accent => switch (animation.membership) {
        AdminSiteAnimationMembership.gold => const Color(0xFFFFD54F),
        AdminSiteAnimationMembership.premium => const Color(0xFFB388FF),
        AdminSiteAnimationMembership.diamond => const Color(0xFF7DF9FF),
        AdminSiteAnimationMembership.vip => const Color(0xFF69F0AE),
        AdminSiteAnimationMembership.svip => const Color(0xFFFF6EC7),
        AdminSiteAnimationMembership.admin => const Color(0xFFFF5252),
        AdminSiteAnimationMembership.host => const Color(0xFFFFD54F),
        _ => Colors.white70,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF12082A),
        border: Border.all(
          color: animation.isActive
              ? _accent.withValues(alpha: 0.45)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    _accent.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: animation.category == AdminSiteAnimationCategory.entrance
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: SiteAnimationEntranceCard(
                        compact: true,
                        command: SiteAnimationCommand(
                          eventId: 'lib:${animation.id}',
                          roomId: 'library',
                          type: SiteAnimationType.memberJoined,
                          tier: _siteTier(animation.membership),
                          userId: 'preview',
                          userName: 'Önizleme',
                          animationId: animation.id,
                          catalogLabel: animation.description ?? animation.name,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Center(
                          child: Icon(
                            _categoryIcon(animation.category),
                            size: 42,
                            color: _accent.withValues(alpha: 0.85),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: animation.isActive
                                  ? Colors.green.withValues(alpha: 0.25)
                                  : Colors.grey.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              animation.isActive ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: animation.isActive
                                    ? Colors.greenAccent
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animation.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${animation.category.label} · ${animation.membership.label}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  '${animation.durationMs}ms · P${animation.priority}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _ActionChip(label: 'Önizle', onTap: onPreview),
                _ActionChip(label: 'Düzenle', onTap: onEdit),
                _ActionChip(label: 'Ata', onTap: onAssign),
                _ActionChip(
                  label: animation.isActive ? 'Pasifleştir' : 'Aktifleştir',
                  onTap: onToggleActive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SiteAnimationTier _siteTier(AdminSiteAnimationMembership m) => switch (m) {
        AdminSiteAnimationMembership.gold => SiteAnimationTier.gold,
        AdminSiteAnimationMembership.premium => SiteAnimationTier.premium,
        AdminSiteAnimationMembership.diamond => SiteAnimationTier.diamond,
        AdminSiteAnimationMembership.vip => SiteAnimationTier.vip,
        AdminSiteAnimationMembership.svip => SiteAnimationTier.svip,
        AdminSiteAnimationMembership.admin => SiteAnimationTier.admin,
        AdminSiteAnimationMembership.host => SiteAnimationTier.host,
        _ => SiteAnimationTier.normal,
      };

  IconData _categoryIcon(AdminSiteAnimationCategory c) => switch (c) {
        AdminSiteAnimationCategory.entrance => Icons.login_rounded,
        AdminSiteAnimationCategory.exit => Icons.logout_rounded,
        AdminSiteAnimationCategory.seat => Icons.event_seat_rounded,
        AdminSiteAnimationCategory.mic => Icons.mic_rounded,
        AdminSiteAnimationCategory.host => Icons.star_rounded,
        AdminSiteAnimationCategory.roomWide => Icons.auto_awesome_rounded,
        _ => Icons.animation_rounded,
      };
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppThemeColors.accentPurple.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
