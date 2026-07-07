import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/performance/list_perf.dart';

/// Sesli Odalar keşfet — TikTok seviyesi scroll / ilk kare hedefleri.
abstract final class VoiceRoomsPerf {
  static const firstPaintTargetMs = 700;

  static const nearbyPageSize = 6;

  static const horizontalCacheExtent = ListPerf.cacheExtent;

  static final scrollCacheExtent =
      ScrollCacheExtent.pixels(horizontalCacheExtent);

  static const scrollPreloadPx = ListPerf.preloadThresholdPx;

  static const nearbyTileExtent = 100.0;

  static const sidebarLazyDelay = Duration(milliseconds: 120);

  static const imagePrefetchMax = 12;

  static const imageThumbnailWidth = 128;

  static ScrollPhysics get scrollPhysics => ListPerf.listPhysics;

  static Widget section(Widget child, {String? label}) {
    return RepaintBoundary(child: child);
  }
}
