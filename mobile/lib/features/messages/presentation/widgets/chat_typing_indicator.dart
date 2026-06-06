import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';


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
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
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
        color: AppThemeColors.accentPink,
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
