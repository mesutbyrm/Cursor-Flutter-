import 'dart:math' as math;

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

  /// [SliverGridDelegate] türünden sütun sayısı ve oran çıkararak yükseklik hesaplar.
  static double nestedGridHeightForDelegate({
    required int itemCount,
    required SliverGridDelegate gridDelegate,
    required double crossAxisExtent,
  }) {
    if (itemCount <= 0) return 0;

    if (gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
      return nestedGridHeight(
        itemCount: itemCount,
        crossAxisCount: gridDelegate.crossAxisCount,
        mainAxisSpacing: gridDelegate.mainAxisSpacing,
        crossAxisSpacing: gridDelegate.crossAxisSpacing,
        childAspectRatio: gridDelegate.childAspectRatio,
        crossAxisExtent: crossAxisExtent,
      );
    }

    if (gridDelegate is SliverGridDelegateWithMaxCrossAxisExtent) {
      final spacing = gridDelegate.crossAxisSpacing;
      final crossAxisCount = math.max(
        1,
        ((crossAxisExtent + spacing) /
                (gridDelegate.maxCrossAxisExtent + spacing))
            .floor(),
      );
      return nestedGridHeight(
        itemCount: itemCount,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: gridDelegate.mainAxisSpacing,
        crossAxisSpacing: spacing,
        childAspectRatio: gridDelegate.childAspectRatio,
        crossAxisExtent: crossAxisExtent,
      );
    }

    return nestedGridHeight(
      itemCount: itemCount,
      crossAxisCount: 1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      crossAxisExtent: crossAxisExtent,
    );
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
