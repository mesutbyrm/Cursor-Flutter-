import 'package:flutter/animation.dart';

import '../motion/canlifal_motion_tokens.dart';

/// CDS motion süreleri — [CanlifalMotionTokens] ile hizalı.
abstract final class CdsMotion {
  static const Duration fast = CanlifalMotionTokens.micro;
  static const Duration standard = CanlifalMotionTokens.normal;
  static const Duration emphasis = CanlifalMotionTokens.premium;

  static const Curve easeOut = CanlifalMotionTokens.easeOut;
  static const Curve easeIn = CanlifalMotionTokens.easeIn;
}
