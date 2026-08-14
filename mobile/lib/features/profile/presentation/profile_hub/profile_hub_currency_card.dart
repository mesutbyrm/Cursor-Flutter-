import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_screen_state.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';
import '../widgets/premium/profile_glass.dart';

/// Jeton, elmas, beğeni, seri + seviye/XP kartı.
class ProfileHubCurrencyCard extends ConsumerWidget {
  const ProfileHubCurrencyCard({super.key, required this.state});

  final ProfileScreenState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extAsync = ref.watch(profileExtendedProvider);
    final ext = extAsync.valueOrNull ?? const ProfileExtendedEntity();
    final level = state.level;
    final xpTarget = level.xpToNext > 0 ? level.xpToNext : 100;
    final xpProgress = (level.xp / xpTarget).clamp(0.0, 1.0);
    final loading = extAsync.isLoading &&
        extAsync.valueOrNull == null &&
        level.xp <= 0 &&
        level.level <= 1;
    final membershipInfo = resolveProfileMembership(
      rawMembership: state.membership ?? state.wallet?.membership,
      daysRemaining: state.membershipDays,
    );

    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      borderRadius: ProfilePremiumTheme.radiusMd,
      borderColor: ProfilePremiumTheme.glassBorder,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: ProfilePremiumTheme.neonPurple,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Seviye ${level.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: loading ? null : xpProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        color: ProfilePremiumTheme.neonPurple,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loading
                          ? '…'
                          : '${profileFormatCount(level.xp)} / ${profileFormatCount(xpTarget)} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _CurrencyCell(
                        icon: Icons.monetization_on_rounded,
                        color: const Color(0xFFFFD54F),
                        label: 'Jeton',
                        value: profileFormatCount(state.jeton),
                        showPlus: true,
                        onPlus: () => openJetonStore(context, ref: ref),
                        loading: loading,
                      ),
                    ),
                    Expanded(
                      child: _CurrencyCell(
                        icon: Icons.diamond_rounded,
                        color: const Color(0xFF64B5F6),
                        label: 'Elmas',
                        value: profileFormatCount(state.cfc),
                        showPlus: true,
                        onPlus: () => openCfcStore(context, ref: ref),
                        loading: loading,
                      ),
                    ),
                    Expanded(
                      child: _CurrencyCell(
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFFF4D9D),
                        label: 'Beğeni',
                        value: profileFormatCount(state.likes),
                        loading: loading,
                      ),
                    ),
                    Expanded(
                      child: _CurrencyCell(
                        icon: Icons.local_fire_department_rounded,
                        color: ProfilePremiumTheme.neonPurple,
                        label: 'Günlük Seri',
                        value: profileFormatCount(ext.dailyStreak),
                        loading: loading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MembershipSummaryRow(info: membershipInfo),
        ],
      ),
    );
  }
}

class _MembershipSummaryRow extends StatelessWidget {
  const _MembershipSummaryRow({required this.info});

  final ProfileMembershipInfo info;

  @override
  Widget build(BuildContext context) {
    final paid = info.hasPaidTier;
    final days = info.daysRemaining;
    final subtitle = paid
        ? (days != null && days > 0
            ? '$days gün kaldı'
            : 'Aktif üyelik')
        : 'Gold, Diamond ve SVIP planları';

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/premium-membership'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                paid ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                color: paid
                    ? ProfilePremiumTheme.neonPurple
                    : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paid ? '${info.tierLabel} Üyelik' : 'Üyelik Planları',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                paid ? 'Yönet' : 'Yükselt',
                style: TextStyle(
                  color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyCell extends StatelessWidget {
  const _CurrencyCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.showPlus = false,
    this.onPlus,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool showPlus;
  final VoidCallback? onPlus;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        if (loading)
          const PremiumSkeleton(width: 36, height: 14)
        else
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showPlus && onPlus != null) ...[
          const SizedBox(height: 4),
          Material(
            color: color.withValues(alpha: 0.2),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPlus,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 12, color: color),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
