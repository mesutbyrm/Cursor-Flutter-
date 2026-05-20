import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';

class DiscoverSectionHeader extends StatelessWidget {
  const DiscoverSectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'Tümünü gör',
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppDesign.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
