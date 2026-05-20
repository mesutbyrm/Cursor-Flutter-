import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hafif neon çerçeveli kart — ana sayfa / şerit bölümleri için.
class GlowPanel extends StatelessWidget {
  const GlowPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 12),
    this.borderRadius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accent.withValues(alpha: 0.45),
            AppTheme.accentSecondary.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 1),
          color: AppTheme.surface.withValues(alpha: 0.94),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Bölüm başlığı + isteğe bağlı aksiyon.
class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accent.withValues(alpha: 0.14),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
