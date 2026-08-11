import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:canlifal_social/features/vip_gold/domain/entrance_theme.dart';

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

/// VIP giriş banner — takım renkleri + altın çerçeve.
class LiveVipEntranceBanner extends StatefulWidget {
  const LiveVipEntranceBanner({
    super.key,
    required this.displayName,
    this.theme,
    this.onDone,
  });

  final String displayName;
  final EntranceTheme? theme;
  final VoidCallback? onDone;

  @override
  State<LiveVipEntranceBanner> createState() => _LiveVipEntranceBannerState();
}

class _LiveVipEntranceBannerState extends State<LiveVipEntranceBanner> {
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    _doneTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? EntranceTheme.turkey;
    final subtitle = theme.teamName != null
        ? '${theme.teamName} taraftarı'
        : (theme.isDefaultTurkey ? '🇹🇷' : null);

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: theme.bannerGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: theme.glowColor,
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (theme.logoUrl != null && theme.logoUrl!.isNotEmpty)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: theme.logoUrl!,
                  width: 22,
                  height: 22,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.workspace_premium_rounded,
                    color: theme.iconColor,
                    size: 20,
                  ),
                ),
              )
            else
              Icon(Icons.workspace_premium_rounded, color: theme.iconColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.displayName} yayına katıldı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
