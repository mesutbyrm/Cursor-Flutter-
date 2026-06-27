import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/voice_room_tokens.dart';

/// PK alt bar — Destekle · Hediye (neon) · Sohbet.
class PkActionBottomBar extends StatelessWidget {
  const PkActionBottomBar({
    super.key,
    required this.onSupport,
    required this.onGift,
    required this.onChat,
  });

  final VoidCallback onSupport;
  final VoidCallback onGift;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 10),
      child: Row(
        children: [
          _PkCircleAction(
            icon: Icons.auto_awesome_rounded,
            label: 'Destekle',
            color: VoiceRoomTokens.neonPurple,
            onTap: onSupport,
          ),
          const Spacer(),
          _PkGiftFab(onTap: onGift),
          const Spacer(),
          _PkCircleAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Sohbet',
            color: const Color(0xFF2A2D45),
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

class _PkCircleAction extends StatelessWidget {
  const _PkCircleAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: color == const Color(0xFF2A2D45) ? 1 : 0.35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: color == VoiceRoomTokens.neonPurple
                  ? VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple, blur: 14)
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _PkGiftFab extends StatefulWidget {
  const _PkGiftFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_PkGiftFab> createState() => _PkGiftFabState();
}

class _PkGiftFabState extends State<_PkGiftFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = 18 + _pulse.value * 14;
          return Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D7A), Color(0xFFB832FF)],
              ),
              boxShadow: VoiceRoomTokens.neonGlow(
                VoiceRoomTokens.neonPink,
                blur: glow,
              ),
            ),
            child: child,
          );
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
            Text(
              'Hediye',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.02, 1.02),
          duration: 1200.ms,
        );
  }
}
