import 'package:flutter/material.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';
import '../../../vip_gold/domain/vip_tier.dart';

/// Profil / sohbet yanında küçük yetki rozeti.
class FxAuthorityBadge extends StatelessWidget {
  const FxAuthorityBadge({
    super.key,
    required this.rank,
    this.compact = true,
  });

  final VoiceStaffRank rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (rank == VoiceStaffRank.none) return const SizedBox.shrink();

    final label = _label(rank);
    final color = _color(rank);

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static String _label(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => 'ADMIN',
        VoiceStaffRank.founder => 'KURUCU',
        VoiceStaffRank.sop => 'SOP',
        VoiceStaffRank.op => 'OP',
        VoiceStaffRank.voice => 'MOD',
        VoiceStaffRank.none => '',
      };

  static Color _color(VoiceStaffRank rank) => switch (rank) {
        VoiceStaffRank.admin => const Color(0xFFFF5252),
        VoiceStaffRank.founder => const Color(0xFFE040FB),
        VoiceStaffRank.sop => VoiceRoomTokens.neonPurple,
        VoiceStaffRank.op => const Color(0xFF40C4FF),
        VoiceStaffRank.voice => VoiceRoomTokens.gold,
        VoiceStaffRank.none => Colors.white70,
      };
}

/// Üyelik rozeti — Gold / Premium / Diamond.
class FxMembershipBadgeChip extends StatelessWidget {
  const FxMembershipBadgeChip({
    super.key,
    required this.tier,
    this.compact = true,
  });

  final VipTier tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!tier.isVip && tier != VipTier.gold) return const SizedBox.shrink();

    final label = switch (tier) {
      VipTier.diamond => 'DIAMOND',
      VipTier.premium => 'PREMIUM',
      VipTier.gold => 'GOLD',
      VipTier.svip => 'SVIP',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();

    final color = switch (tier) {
      VipTier.diamond => const Color(0xFF7DF9FF),
      VipTier.premium => const Color(0xFFB388FF),
      VipTier.gold => VoiceRoomTokens.gold,
      VipTier.svip => const Color(0xFFFF6EC7),
      _ => Colors.white70,
    };

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 7.5 : 8.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
