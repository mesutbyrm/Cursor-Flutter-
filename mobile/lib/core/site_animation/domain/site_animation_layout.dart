import 'package:flutter/material.dart';

enum SiteAnimationAnchor {
  topLeft,
  topCenter,
  seat,
  custom,
}

/// Admin / backend konumlandırma override'ları.
class SiteAnimationLayout {
  const SiteAnimationLayout({
    this.anchor = SiteAnimationAnchor.topLeft,
    this.position,
    this.scale = 1,
    this.durationMs,
    this.seatIndex,
    this.fromSeatIndex,
  });

  final SiteAnimationAnchor anchor;
  final Offset? position;
  final double scale;
  final int? durationMs;
  final int? seatIndex;
  final int? fromSeatIndex;

  SiteAnimationLayout copyWith({
    SiteAnimationAnchor? anchor,
    Offset? position,
    double? scale,
    int? durationMs,
    int? seatIndex,
    int? fromSeatIndex,
  }) {
    return SiteAnimationLayout(
      anchor: anchor ?? this.anchor,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      durationMs: durationMs ?? this.durationMs,
      seatIndex: seatIndex ?? this.seatIndex,
      fromSeatIndex: fromSeatIndex ?? this.fromSeatIndex,
    );
  }
}
