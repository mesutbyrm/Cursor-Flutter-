import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Kaybeden taraf animasyonu — grileşme, sarsılma ve «KAYBETTİ» damgası.
class PkLoserSideOverlay extends StatelessWidget {
  const PkLoserSideOverlay({
    super.key,
    required this.visible,
    this.alignment = Alignment.center,
  });

  final bool visible;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sentiment_very_dissatisfied_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.7),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shake(hz: 3, duration: 600.ms),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Text(
                        'KAYBETTİ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
