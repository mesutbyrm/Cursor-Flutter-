import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Günlük fal ekranları — koyu kare ikon butonu (mockup).
class FortuneMysticBarButton extends StatelessWidget {
  const FortuneMysticBarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A0B2E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }
}
