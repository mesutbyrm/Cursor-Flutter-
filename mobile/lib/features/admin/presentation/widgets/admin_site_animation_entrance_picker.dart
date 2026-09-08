import 'package:flutter/material.dart';

import '../../../../core/site_animation/presentation/widgets/site_animation_entrance_card.dart';
import '../../../../core/site_animation/domain/site_animation_command.dart';
import '../../../../core/site_animation/domain/site_animation_tier.dart';
import '../../../../core/site_animation/domain/site_animation_type.dart';
import '../../domain/admin_site_animation.dart';

/// Giriş animasyonu seçimi — tasarım referansı kart önizlemeli grid.
class AdminSiteAnimationEntrancePicker extends StatelessWidget {
  const AdminSiteAnimationEntrancePicker({
    super.key,
    required this.tier,
    required this.animations,
    required this.selectedId,
    required this.onSelected,
  });

  final AdminSiteAnimationMembership tier;
  final List<AdminSiteAnimation> animations;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  SiteAnimationTier get _siteTier => switch (tier) {
        AdminSiteAnimationMembership.gold => SiteAnimationTier.gold,
        AdminSiteAnimationMembership.premium => SiteAnimationTier.premium,
        AdminSiteAnimationMembership.diamond => SiteAnimationTier.diamond,
        AdminSiteAnimationMembership.vip => SiteAnimationTier.vip,
        AdminSiteAnimationMembership.svip => SiteAnimationTier.svip,
        AdminSiteAnimationMembership.admin => SiteAnimationTier.admin,
        AdminSiteAnimationMembership.host => SiteAnimationTier.host,
        _ => SiteAnimationTier.normal,
      };

  @override
  Widget build(BuildContext context) {
    final filtered = animations
        .where((a) =>
            a.category == AdminSiteAnimationCategory.entrance && a.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _OptionTile(
              label: '— Seçilmedi —',
              selected: selectedId == null,
              onTap: () => onSelected(null),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: Text(
                  'Varsayılan yok',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            for (final anim in filtered)
              _OptionTile(
                label: anim.name,
                selected: selectedId == anim.id,
                onTap: () => onSelected(anim.id),
                child: SiteAnimationEntranceCard(
                  compact: true,
                  command: SiteAnimationCommand(
                    eventId: 'pick:${anim.id}',
                    roomId: 'picker',
                    type: SiteAnimationType.memberJoined,
                    tier: _siteTier,
                    userId: 'preview',
                    userName: 'Önizleme',
                    animationId: anim.id,
                    catalogLabel: anim.description ?? anim.name,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF12082A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF8B4DFF)
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
