import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// «Yazıyor…» animasyonu — Discord tarzı üç nokta.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key, this.label = 'Yazıyor'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _Dot(delay: 0),
          const SizedBox(width: 4),
          _Dot(delay: 150),
          const SizedBox(width: 4),
          _Dot(delay: 300),
          const SizedBox(width: 8),
          Text(
            '$label…',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.accentPink,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(duration: 400.ms, delay: delay.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 400.ms,
          delay: delay.ms,
        );
  }
}
