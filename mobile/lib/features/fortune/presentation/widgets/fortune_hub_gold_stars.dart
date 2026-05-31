import 'package:flutter/material.dart';

/// Mockup — üçlü altın yıldız kümesi.
class FortuneHubGoldStars extends StatelessWidget {
  const FortuneHubGoldStars({
    super.key,
    this.size = 10,
    this.spacing = 2,
  });

  final double size;
  final double spacing;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Star(size: size * 0.85, opacity: 0.75),
        SizedBox(width: spacing),
        _Star(size: size),
        SizedBox(width: spacing),
        _Star(size: size * 0.9, opacity: 0.85),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.size, this.opacity = 1});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: FortuneHubGoldStars._gold.withValues(alpha: opacity),
      shadows: [
        Shadow(
          color: FortuneHubGoldStars._gold.withValues(alpha: 0.6),
          blurRadius: 6,
        ),
      ],
    );
  }
}
