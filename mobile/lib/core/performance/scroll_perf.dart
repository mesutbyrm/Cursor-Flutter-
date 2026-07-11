import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'list_perf.dart';

/// Scroll performansı — 60 FPS, frame drop yok.
abstract final class ScrollPerf {
  /// Varsayılan dikey liste önbellek alanı (px).
  static const double cacheExtent = ListPerf.cacheExtent;

  /// Sosyal feed / ana sayfa CustomScrollView.
  static const double feedCacheExtent = 560;

  /// Sohbet / canlı yorum akışı.
  static const double chatCacheExtent = 320;

  /// İç içe profil / ana sayfa grid.
  static const double gridCacheExtent = 400;

  /// Yatay story / karusel.
  static const double horizontalCacheExtent = 360;

  /// Sayfalama scroll dinleyicisi throttle (px).
  static const double paginationThrottlePx = 48;

  static const ScrollPhysics feedPhysics = ListPerf.listPhysics;

  /// Flutter 3.41+ [scrollCacheExtent] için px sarmalayıcı.
  static ScrollCacheExtent scrollCache(double pixels) =>
      ScrollCacheExtent.pixels(pixels);

  /// Liste öğesi — scroll sırasında komşu satırlar repaint etmesin.
  static Widget item(Widget child) => ListPerf.repaint(child);

  /// [CustomScrollView] / [ListView] için önerilen cacheExtent.
  static double cacheFor(ScrollSurface surface) => switch (surface) {
        ScrollSurface.feed => feedCacheExtent,
        ScrollSurface.chat => chatCacheExtent,
        ScrollSurface.grid => gridCacheExtent,
        ScrollSurface.horizontal => horizontalCacheExtent,
        ScrollSurface.shortsFeed => feedCacheExtent * 1.5,
        ScrollSurface.standard => cacheExtent,
      };

  /// Uç yaklaşınca `loadMore` — her pikselde değil, throttle ile.
  /// Dönüş: dinleyiciyi kaldırmak için `dispose` içinde çağırın.
  static VoidCallback bindPagination(
    ScrollController controller,
    VoidCallback onNearEnd, {
    double thresholdPx = 520,
  }) {
    var lastFiredOffset = double.negativeInfinity;

    void listener() {
      if (!controller.hasClients) return;
      final position = controller.position;
      final offset = position.pixels;
      final nearEnd = offset >= position.maxScrollExtent - thresholdPx;
      if (!nearEnd) return;

      if ((offset - lastFiredOffset).abs() < paginationThrottlePx) return;
      lastFiredOffset = offset;

      SchedulerBinding.instance.scheduleFrameCallback((_) => onNearEnd());
    }

    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }
}

enum ScrollSurface {
  standard,
  feed,
  chat,
  grid,
  horizontal,
  shortsFeed,
}
