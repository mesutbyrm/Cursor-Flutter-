import 'package:flutter/material.dart';

import '../../theme/home_approved_design.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.emoji,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        12,
        HomeApprovedDesign.hPad,
        8,
      ),
      child: Row(
        children: [
          Text(
            '$emoji $title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: HomeApprovedDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HomeApprovedDesign.purple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
