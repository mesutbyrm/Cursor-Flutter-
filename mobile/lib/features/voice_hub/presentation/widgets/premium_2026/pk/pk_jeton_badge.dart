import 'package:flutter/material.dart';

import '../../../theme/voice_room_tokens.dart';
import 'pk_animated_score_bar.dart';

/// Tek tarafın PK jeton skoru — TikTok tarzı rozet.
class PkJetonBadge extends StatelessWidget {
  const PkJetonBadge({
    super.key,
    required this.jeton,
    required this.accent,
    this.compact = false,
  });

  final int jeton;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: compact ? 12 : 14,
            color: VoiceRoomTokens.gold,
          ),
          const SizedBox(width: 4),
          Text(
            PkAnimatedScoreBar.fmt(jeton),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: compact ? 11 : 13,
              color: Colors.white,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 3),
            Text(
              'Jeton',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
