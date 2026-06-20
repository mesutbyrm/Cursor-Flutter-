import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Emoji kullanmayan premium shimmer placeholder.
class FortuneImageShimmer extends StatelessWidget {
  const FortuneImageShimmer({
    super.key,
    required this.accent,
  });

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: accent.withValues(alpha: 0.12),
      highlightColor: accent.withValues(alpha: 0.32),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.08),
              const Color(0xFF0A0118),
            ],
          ),
        ),
      ),
    );
  }
}
