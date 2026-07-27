import 'package:flutter/painting.dart';

/// Uygulama geneli görsel önbellek yardımcıları.
abstract final class CanlifalImageCache {
  static const maxBytes = 100 << 20; // 100 MB

  static void configure() {
    PaintingBinding.instance.imageCache
      ..maximumSize = 200
      ..maximumSizeBytes = maxBytes;
  }

  /// Oda çıkışında bellek baskısını azaltır (tam temizlik değil).
  static void trimIfNeeded() {
    final cache = PaintingBinding.instance.imageCache;
    if (cache.currentSizeBytes > (maxBytes * 0.85).round()) {
      cache.clear();
      cache.clearLiveImages();
    }
  }
}
