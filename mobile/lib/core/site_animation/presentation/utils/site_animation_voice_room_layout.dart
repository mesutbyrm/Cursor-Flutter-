import 'dart:math' as math;

import 'package:flutter/material.dart';

/// `VoiceWebOwnerStage` ile aynı geometri — preview ve koltuk overlay hizası.
class SiteAnimationVoiceRoomLayoutMetrics {
  const SiteAnimationVoiceRoomLayoutMetrics({
    required this.hostSize,
    required this.cell,
    required this.rowH,
    required this.totalH,
    required this.topSeats,
    required this.bottomSeats,
  });

  final double hostSize;
  final double cell;
  final double rowH;
  final double totalH;
  final List<int> topSeats;
  final List<int> bottomSeats;
}

/// Overlay içinde giriş paneli / koltuk sahnesi konumları.
class SiteAnimationVoiceRoomLayoutScope extends InheritedWidget {
  const SiteAnimationVoiceRoomLayoutScope({
    super.key,
    required this.stageTop,
    required super.child,
  });

  /// Koltuk sahnesinin overlay içindeki Y başlangıcı (header sonrası).
  final double stageTop;

  static SiteAnimationVoiceRoomLayoutScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SiteAnimationVoiceRoomLayoutScope>();
  }

  @override
  bool updateShouldNotify(SiteAnimationVoiceRoomLayoutScope oldWidget) =>
      oldWidget.stageTop != stageTop;
}

abstract final class SiteAnimationVoiceRoomLayout {
  static const hPad = 8.0;
  static const gap = 6.0;
  static const headerHeight = 76.0;

  static SiteAnimationVoiceRoomLayoutMetrics metrics(double width) {
    final innerW = width - hPad * 2;
    final hostSize = (innerW * 0.17).clamp(52.0, 72.0);
    final gridW = innerW - hostSize - gap;
    final cell = ((gridW - gap * 4) / 5).clamp(34.0, 50.0);
    final rowH = cell + 20;
    final gridH = rowH * 2 + gap;
    final totalH = gridH.clamp(112.0, 176.0);
    return SiteAnimationVoiceRoomLayoutMetrics(
      hostSize: hostSize,
      cell: cell,
      rowH: rowH,
      totalH: totalH,
      topSeats: const [2, 3, 4, 5, 6],
      bottomSeats: const [7, 8, 9, 10, 11],
    );
  }

  static Rect entrancePanelRect(Size size, {double stageTop = 0}) {
    final width = size.width.clamp(280.0, 500.0);
    final panelW = (width * 0.88).clamp(280.0, 360.0);
    final panelH = (panelW * 0.28).clamp(70.0, 110.0);
    return Rect.fromLTWH(12, stageTop + 8, panelW, panelH);
  }

  static Rect seatRect(
    BuildContext context,
    int seatIndex, {
    double stageTop = 0,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final m = metrics(width);
    final center = seatCenter(width, seatIndex, stageTop: stageTop, metrics: m);
    final size = seatIndex == 1 ? m.hostSize : m.cell;
    return Rect.fromCenter(center: center, width: size, height: size);
  }

  static Offset seatCenter(
    double width,
    int seatIndex, {
    double stageTop = 0,
    SiteAnimationVoiceRoomLayoutMetrics? metrics,
  }) {
    final m = metrics ?? SiteAnimationVoiceRoomLayout.metrics(width);
    final stageLeft = hPad;

    if (seatIndex == 1) {
      return Offset(
        stageLeft + m.hostSize / 2,
        stageTop + m.totalH / 2,
      );
    }

    final gridLeft = stageLeft + m.hostSize + gap;
    final topY = stageTop + (m.totalH - m.rowH * 2 - gap) / 2 + m.cell / 2;
    final bottomY = topY + m.rowH + gap;

    final topIdx = m.topSeats.indexOf(seatIndex);
    if (topIdx >= 0) {
      final cols = m.topSeats.length;
      final x = _gridX(gridLeft, m.cell, gap, cols, topIdx);
      return Offset(x, topY);
    }

    final bottomIdx = m.bottomSeats.indexOf(seatIndex);
    if (bottomIdx >= 0) {
      final cols = m.bottomSeats.length;
      final x = _gridX(gridLeft, m.cell, gap, cols, bottomIdx);
      return Offset(x, bottomY);
    }

    // Fallback: 4-col legacy grid
    const cols = 4;
    final col = seatIndex % cols;
    final row = seatIndex ~/ cols;
    return Offset(
      hPad + col * (width - hPad * 2) / cols + m.cell / 2,
      stageTop + 108 + row * 84,
    );
  }

  static double _gridX(
    double gridLeft,
    double cell,
    double gap,
    int cols,
    int index,
  ) {
    final gridW = cols * cell + (cols - 1) * gap;
    final start = gridLeft + math.max(0, (gridW - cols * cell - (cols - 1) * gap) / 2);
    return start + index * (cell + gap) + cell / 2;
  }
}
