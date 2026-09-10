import 'package:flutter/material.dart';

import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Hub / katalog boş, hata veya bilgi durumu — premium liquid panel.
class UltraFortuneStatePanel extends StatelessWidget {
  const UltraFortuneStatePanel({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.height,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height ?? 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white54),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: UltraFortuneTokens.metallicGold,
                  foregroundColor: const Color(0xFF1A0A32),
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
