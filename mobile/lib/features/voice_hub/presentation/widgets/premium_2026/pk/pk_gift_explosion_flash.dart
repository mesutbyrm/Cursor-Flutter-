import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/voice_room_tokens.dart';

/// Hediye gücü patlaması — kısa neon flash.
class PkGiftExplosionFlash extends StatelessWidget {
  const PkGiftExplosionFlash({
    super.key,
    required this.token,
    required this.toLeft,
  });

  final int token;
  final bool toLeft;

  @override
  Widget build(BuildContext context) {
    if (token == 0) return const SizedBox.shrink();

    final color = toLeft ? VoiceRoomTokens.neonPink : VoiceRoomTokens.neonBlue;

    return IgnorePointer(
      child: Align(
        alignment: toLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: toLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: Alignment.center,
                colors: [
                  color.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(key: ValueKey(token))
        .fadeIn(duration: 120.ms)
        .fadeOut(delay: 280.ms, duration: 400.ms);
  }
}
