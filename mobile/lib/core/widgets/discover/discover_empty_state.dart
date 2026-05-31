import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'discover_glass_card.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DiscoverGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 15,
              ),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: action,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
