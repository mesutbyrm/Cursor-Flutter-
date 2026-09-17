import 'package:flutter/material.dart';

import '../../../domain/pk/live_pk_status_pill_mode.dart';

/// TikTok/Bigo — skor barının altında sabit durum pill'i.
class PkStatusPill extends StatelessWidget {
  const PkStatusPill({
    super.key,
    required this.mode,
    this.winnerName,
    this.highlight = false,
  });

  final PkStatusPillMode mode;
  final String? winnerName;
  final bool highlight;

  String get label {
    switch (mode) {
      case PkStatusPillMode.active:
        return 'PK devam ediyor!';
      case PkStatusPillMode.endedDraw:
        return 'Berabere!';
      case PkStatusPillMode.endedWin:
        final name = winnerName?.trim() ?? '';
        if (name.isEmpty) return 'Kazanan belli oldu!';
        return '$name kazandı!';
    }
  }

  IconData get icon {
    switch (mode) {
      case PkStatusPillMode.active:
        return Icons.bolt_rounded;
      case PkStatusPillMode.endedDraw:
        return Icons.handshake_rounded;
      case PkStatusPillMode.endedWin:
        return Icons.emoji_events_rounded;
    }
  }

  Color get accent {
    switch (mode) {
      case PkStatusPillMode.active:
        return const Color(0xFFFFD54F);
      case PkStatusPillMode.endedDraw:
        return const Color(0xFF90CAF9);
      case PkStatusPillMode.endedWin:
        return const Color(0xFFFFD54F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
