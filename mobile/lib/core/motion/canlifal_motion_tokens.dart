import 'package:flutter/animation.dart';

/// Canlifal global motion dili — CDS + Premium2026 ile hizalı.
abstract final class CanlifalMotionTokens {
  // Micro (120–180ms)
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration microMax = Duration(milliseconds: 180);

  // Normal (200–300ms)
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration normalMax = Duration(milliseconds: 300);

  // Premium / special (350–600ms)
  static const Duration premium = Duration(milliseconds: 420);
  static const Duration premiumMax = Duration(milliseconds: 560);

  static const Duration sheet = Duration(milliseconds: 380);
  static const Duration page = Duration(milliseconds: 280);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve expo = Curves.easeOutExpo;

  // Web (canlifal.com, framer-motion) ile birebir: içerik `opacity 0 → 1`,
  // `y 20 → 0`, 0.3 sn; liste elemanları `delay: i * 0.05`; modal scale 0.9 → 1.
  static const Duration webEnter = Duration(milliseconds: 300);
  static const Duration webStagger = Duration(milliseconds: 50);
  static const double webRisePx = 20;
  static const double webModalScale = 0.9;

  static const double pressScale = 0.96;
  static const double navActiveScale = 1.08;

  static Duration staggerIndex(int index, {int stepMs = 40}) {
    return Duration(milliseconds: (index * stepMs).clamp(0, 200));
  }
}
