import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../theme/home_palette.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingLabel = 'Tümünü Gör',
    this.onTrailing,
    this.leadingDotColor,
  });

  final String title;
  final String? subtitle;
  final String trailingLabel;
  final VoidCallback? onTrailing;
  final Color? leadingDotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: BoxDecoration(
                color: leadingDotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: leadingDotColor!.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: context.colors.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTrailing != null)
            TextButton(
              onPressed: onTrailing,
              child: Text(
                trailingLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: HomePalette.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
