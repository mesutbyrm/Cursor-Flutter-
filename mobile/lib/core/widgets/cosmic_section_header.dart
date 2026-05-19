import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Web’deki “Önerilen Videolar” tarzı: sol kırmızı çubuk + başlık + sağ aksiyon.
class CosmicSectionHeader extends StatelessWidget {
  const CosmicSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showBar = true,
  });

  final String title;
  final Widget? trailing;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBar) ...[
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.sectionBar,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sectionBar.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.35,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
