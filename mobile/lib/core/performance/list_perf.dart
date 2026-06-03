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
}
