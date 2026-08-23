import 'package:flutter/material.dart';

/// 60 FPS hedefi için liste / scroll sabitleri.
abstract final class ListPerf {
  static const double cacheExtent = 480;

  static const ScrollPhysics listPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  static const int defaultPageSize = 24;

  static const int preloadThresholdPx = 520;

  static Widget repaint(Widget child, {String? debugLabel}) {
    return RepaintBoundary(child: child);
  }

  /// Parent [ListView] içinde nested grid — `shrinkWrap` yerine sabit yükseklik.
  static double nestedGridHeight({
    required int itemCount,
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required double childAspectRatio,
    required double crossAxisExtent,
  }) {
    if (itemCount <= 0 || crossAxisCount <= 0) return 0;
    final cellWidth =
        (crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1)) /
        crossAxisCount;
    final cellHeight = cellWidth / childAspectRatio;
    final rows = (itemCount / crossAxisCount).ceil();
    return rows * cellHeight + mainAxisSpacing * (rows - 1);
  }

  /// Parent scroll içinde dikey liste — sabit satır yüksekliği ile.
  static double nestedListHeight({
    required int itemCount,
    required double itemExtent,
    double separatorExtent = 0,
  }) {
    if (itemCount <= 0) return 0;
    return itemCount * itemExtent + separatorExtent * (itemCount - 1);
  }
}
