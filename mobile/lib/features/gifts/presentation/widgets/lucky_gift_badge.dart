import 'package:flutter/material.dart';

/// Şanslı hediye rozeti — katalog kutularında.
class LuckyGiftBadge extends StatelessWidget {
  const LuckyGiftBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
        ),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        compact ? '🍀' : '🍀 Şanslı',
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
