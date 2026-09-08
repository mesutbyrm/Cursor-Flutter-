import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../premium_2026/profile_screen_state.dart';
import '../premium_2026/profile_theme.dart';

/// Profil üst özet — bakiye, seviye, yayın ve yetki tek bakışta.
class ProfileHubSummaryCard extends ConsumerWidget {
  const ProfileHubSummaryCard({super.key, required this.state});

  final ProfileScreenState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffAccessProvider);
    final chips = <Widget>[
      _Chip(
        icon: Icons.monetization_on_rounded,
        label: 'Jeton',
        value: state.jeton,
        color: AppThemeColors.coinGold,
      ),
      _Chip(
        icon: Icons.diamond_rounded,
        label: 'CFC',
        value: state.cfc,
        color: AppThemeColors.accentCyan,
      ),
      _Chip(
        icon: Icons.military_tech_rounded,
        label: 'Lv.${state.level.level}',
        value: '${state.followers} takipçi',
        color: AppThemeColors.accentPink,
      ),
    ];

    if (state.liveStreams > 0) {
      chips.add(
        _Chip(
          icon: Icons.live_tv_rounded,
          label: 'Yayın',
          value: '${state.liveStreams}',
          color: AppThemeColors.liveRed,
        ),
      );
    }

    return Material(
      color: ProfilePremiumTheme.deepBg.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
        onTap: () => context.push('/profile/transactions'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Özet',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (staff.isStaffMember)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        staff.roleLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
