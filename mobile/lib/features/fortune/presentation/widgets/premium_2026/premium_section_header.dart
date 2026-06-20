import 'package:flutter/material.dart';

import '../../data/fortune_type_images.dart';
import '../ultra_premium/ultra_fortune_tokens.dart' as tokens;

/// Fal bölüm başlığı — emoji yerine Material ikon + gold shader.
class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.icon = Icons.auto_awesome_rounded,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? FortuneTypeImages.glowColor('tarot');

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) =>
              tokens.UltraFortuneTokens.goldTypography.createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
