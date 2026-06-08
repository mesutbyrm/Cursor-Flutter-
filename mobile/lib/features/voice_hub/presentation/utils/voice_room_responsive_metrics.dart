import 'package:flutter/material.dart';

/// Sesli oda ekranı — yükseklik tabanlı responsive ölçüler.
class VoiceRoomResponsiveMetrics {
  const VoiceRoomResponsiveMetrics({
    required this.screenH,
    required this.screenW,
    required this.keyboardOpen,
    required this.safeTop,
    required this.safeBottom,
  });

  factory VoiceRoomResponsiveMetrics.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final viewInsets = mq.viewInsets;
    return VoiceRoomResponsiveMetrics(
      screenH: mq.size.height,
      screenW: mq.size.width,
      keyboardOpen: viewInsets.bottom > 0,
      safeTop: mq.padding.top,
      safeBottom: mq.padding.bottom,
    );
  }

  final double screenH;
  final double screenW;
  final bool keyboardOpen;
  final double safeTop;
  final double safeBottom;

  double get seatBlockH {
    if (keyboardOpen) return (screenH * 0.14).clamp(88.0, 120.0);
    final cell = ((screenW - 52) / 4).clamp(38.0, 54.0);
    return (cell + 18) * 2 + 8;
  }

  double get chatBlockH {
    if (keyboardOpen) return (screenH * 0.2).clamp(80.0, 140.0);
    final available = screenH * 0.34;
    return available.clamp(100.0, 200.0);
  }

  double get musicBlockH {
    if (keyboardOpen) return 0;
    return (screenH * 0.16).clamp(72.0, 130.0);
  }

  double get duyuruMaxLines => screenH < 640 ? 1.0 : 2.0;

  double get horizontalPad => screenW < 360 ? 8.0 : 12.0;

  double get sectionGap => keyboardOpen ? 2.0 : 4.0;
}
