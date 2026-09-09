import 'package:flutter/material.dart';

import 'ultra_fortune_tokens.dart';

/// Fal hub lazy bölüm yüklenirken boş alan yerine görünür iskelet.
class UltraFortuneSectionPlaceholder extends StatelessWidget {
  const UltraFortuneSectionPlaceholder({
    super.key,
    this.height = 120,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              UltraFortuneTokens.softLilac.withValues(alpha: 0.12),
              UltraFortuneTokens.deepNight.withValues(alpha: 0.08),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
