import 'package:flutter/material.dart';

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

/// VIP giriş banner — altın çerçeve + parıltı.
class LiveVipEntranceBanner extends StatefulWidget {
  const LiveVipEntranceBanner({
    super.key,
    required this.displayName,
    this.onDone,
  });

  final String displayName;
  final VoidCallback? onDone;

  @override
  State<LiveVipEntranceBanner> createState() => _LiveVipEntranceBannerState();
}

class _LiveVipEntranceBannerState extends State<LiveVipEntranceBanner> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.35),
              const Color(0xFFB832FF).withValues(alpha: 0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.35),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text(
              '${widget.displayName} yayına katıldı',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
