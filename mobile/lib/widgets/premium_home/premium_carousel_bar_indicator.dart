import 'package:flutter/material.dart';

import '../../theme/premium_live_theme.dart';

/// Mockup’taki yatay çubuk sayfa göstergesi: aktif pembe ve daha geniş.
class PremiumCarouselBarIndicator extends StatelessWidget {
  const PremiumCarouselBarIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: i == activeIndex ? 28 : 8,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i == activeIndex
                  ? PremiumLiveTheme.neonPink
                  : Colors.white.withValues(alpha: 0.2),
              boxShadow: i == activeIndex
                  ? [
                      BoxShadow(
                        color: PremiumLiveTheme.neonPink.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}
