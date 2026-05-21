import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class DiscoverIconButton extends StatelessWidget {
  const DiscoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.textSecondary, size: 24),
      ),
    );
  }
}
