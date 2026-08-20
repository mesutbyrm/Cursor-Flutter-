import 'package:flutter/material.dart';

import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';

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
            Icon(
              icon,
              size: 18,
              color: HomePremiumDesign.accent.withValues(alpha: 0.9),
            ),
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
              style: HomePremiumDesign.sectionTitleStyle,
            ),
          ),
          if (actionLabel != null && onAction != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    actionLabel!,
                    style: HomePremiumDesign.actionLabelStyle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
