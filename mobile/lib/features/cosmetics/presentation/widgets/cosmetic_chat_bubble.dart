import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';
import '../../domain/cosmetic_item.dart';

/// Sohbet balonu dekorasyonu — Gold+ kozmetik seçimine göre.
abstract final class CosmeticChatBubbleStyle {
  static BoxDecoration decoration(CosmeticItem? item) {
    if (item == null) return _defaultDecoration();
    return switch (item.effectKind) {
      CosmeticEffectKind.goldText => BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD54F).withValues(alpha: 0.22),
              const Color(0xFFFF8F00).withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
              blurRadius: 10,
            ),
          ],
        ),
      CosmeticEffectKind.neonText => BoxDecoration(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
      CosmeticEffectKind.glassText => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.06),
              blurRadius: 8,
            ),
          ],
        ),
      _ => _defaultDecoration(),
    };
  }

  static BoxDecoration _defaultDecoration() => BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      );

  static Widget preview(CosmeticItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: decoration(item),
      child: Text(
        'Merhaba!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: switch (item.effectKind) {
            CosmeticEffectKind.goldText => const Color(0xFFFFD54F),
            CosmeticEffectKind.neonText => const Color(0xFF80DEEA),
            CosmeticEffectKind.glassText => Colors.white.withValues(alpha: 0.9),
            _ => Colors.white,
          },
        ),
      ),
    );
  }
}
