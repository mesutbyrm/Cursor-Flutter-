import 'package:flutter/material.dart';

/// Premium 2026 hareket dili — TikTok / iOS akıcı eğriler.
abstract final class PremiumMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration sheet = Duration(milliseconds: 420);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve expo = Curves.easeOutExpo;

  static ScrollPhysics listPhysics = const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
    decelerationRate: ScrollDecelerationRate.fast,
  );

  static ScrollPhysics get pagePhysics => listPhysics;
}
