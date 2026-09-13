import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/vip_gold/domain/entrance_theme.dart';
import 'package:canlifal_social/features/vip_gold/domain/entrance_visual_style.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/providers/entrance_effect_settings_provider.dart';
import 'package:canlifal_social/features/vip_gold/presentation/widgets/gold_team_top_entrance_banner.dart';

/// Sohbet rozetleri — VIP, seviye, falcı, moderatör.
enum LiveChatBadgeKind { vip, level, fortuneTeller, moderator }

class LiveVipChatBadge extends StatelessWidget {
  const LiveVipChatBadge({
    super.key,
    required this.kind,
    this.label,
  });

  final LiveChatBadgeKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = switch (kind) {
      LiveChatBadgeKind.vip => (
          const Color(0xFFFFD700),
          Icons.workspace_premium_rounded,
          label ?? 'VIP'
        ),
      LiveChatBadgeKind.level => (
          const Color(0xFF22D3EE),
          Icons.military_tech_rounded,
          label ?? 'Lv'
        ),
      LiveChatBadgeKind.fortuneTeller => (
          const Color(0xFFB832FF),
          Icons.auto_awesome_rounded,
          label ?? 'Falcı'
        ),
      LiveChatBadgeKind.moderator => (
          const Color(0xFF22C55E),
          Icons.shield_rounded,
          label ?? 'MOD'
        ),
    };

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// VIP giriş — Gold+ takım amblemi ile üstten (ayarlanabilir).
class LiveVipEntranceBanner extends ConsumerWidget {
  const LiveVipEntranceBanner({
    super.key,
    required this.displayName,
    this.theme,
    this.tier = VipTier.gold,
    this.onDone,
  });

  final String displayName;
  final EntranceTheme? theme;
  final VipTier tier;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(entranceEffectSettingsProvider);
    final resolved = theme ?? EntranceTheme.turkey;
    if (settings.visualStyle == EntranceVisualStyle.topTeamPass) {
      return GoldTeamTopEntranceBanner(
        userName: displayName,
        tier: tier,
        theme: resolved,
        topInset: 72,
        subtitle: '${resolved.teamName ?? 'Gold'} taraftarı yayına katıldı',
        onFinished: onDone,
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: resolved.bannerGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: resolved.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: resolved.glowColor,
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          '$displayName yayına katıldı',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
