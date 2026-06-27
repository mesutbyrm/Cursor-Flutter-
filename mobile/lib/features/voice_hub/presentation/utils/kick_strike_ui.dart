import 'package:flutter/material.dart';

/// 3 vuruş kick sistemi — sarı / turuncu / kırmızı (web parity).
abstract final class KickStrikeUi {
  static Color colorFor(int strikeCount) {
    final n = strikeCount.clamp(1, 3);
    return switch (n) {
      1 => const Color(0xFFEAB308),
      2 => const Color(0xFFF97316),
      _ => const Color(0xFFEF4444),
    };
  }

  static String titleFor(int strikeCount, {bool autoBanned = false}) {
    if (autoBanned) return 'Otomatik ban';
    return switch (strikeCount.clamp(1, 3)) {
      1 => '1. uyarı',
      2 => '2. uyarı',
      _ => '3. uyarı — ban',
    };
  }

  static String messageFor(int strikeCount, {bool autoBanned = false}) {
    if (autoBanned) {
      return '3 ihtar tamamlandı. Oda sahibi banı kaldırana kadar giriş yapamazsınız.';
    }
    final left = (3 - strikeCount).clamp(0, 2);
    return '$strikeCount/3 ihtar aldınız. '
        '${left > 0 ? '$left kez daha kicklenirseniz otomatik ban uygulanır.' : 'Bir sonraki kick otomatik ban getirir.'}';
  }
}
