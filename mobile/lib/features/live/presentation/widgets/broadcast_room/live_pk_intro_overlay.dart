import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../voice_hub/presentation/theme/voice_room_tokens.dart';

/// PK başlangıç — kısa VS / PK BAŞLADI flaşı.
class LivePkIntroOverlay extends StatefulWidget {
  const LivePkIntroOverlay({super.key, required this.visible});

  final bool visible;

  @override
  State<LivePkIntroOverlay> createState() => _LivePkIntroOverlayState();
}

class _LivePkIntroOverlayState extends State<LivePkIntroOverlay> {
  bool _shown = false;
  bool _display = false;

  @override
  void didUpdateWidget(covariant LivePkIntroOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_shown) {
      _shown = true;
      _display = true;
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _display = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_display) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VS',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [
                      VoiceRoomTokens.neonPink,
                      VoiceRoomTokens.neonPurple,
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 80)),
              ),
            ).animate().scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 420.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 8),
            const Text(
              'PK BAŞLADI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 120.ms),
          ],
        ),
      ),
    );
  }
}
