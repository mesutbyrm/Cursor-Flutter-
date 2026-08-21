import 'package:flutter/painting.dart';

import '../network/api_http_cache.dart';
import '../offline/api_cache_store.dart';
import '../performance/network_perf.dart';

/// Ayarlar > Önbellek temizle — JWT / secure token dokunulmaz.
abstract final class AppCacheClear {
  static Future<void> clearNonAuthCaches() async {
    await NetworkPerf.parallel([
      ApiHttpCache.clearAll(),
      ApiCacheStore.clearAll(),
    ]);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
