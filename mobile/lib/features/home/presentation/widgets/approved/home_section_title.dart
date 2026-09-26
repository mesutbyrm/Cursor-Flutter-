import 'package:flutter/material.dart';

import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/theme/canlifal_brand_colors.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.emoji,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String emoji;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.isDarkTheme
        ? CanlifalBrandColors.violetBright
        : context.colors.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        14,
        HomeApprovedDesign.hPad,
        8,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 6),
          ] else if (emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HomePremiumDesign.sectionTitleStyle.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Semantics(
              button: true,
              label: '$title — $actionLabel',
              onTap: onAction,
              excludeSemantics: true,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: HomePremiumDesign.actionLabelStyle.copyWith(
                            color: accent,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
