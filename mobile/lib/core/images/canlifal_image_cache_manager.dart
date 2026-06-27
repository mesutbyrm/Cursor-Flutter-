import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Uygulama geneli görsel disk önbelleği — 30 gün, 600 dosya.
class CanlifalImageCacheManager extends CacheManager {
  CanlifalImageCacheManager._()
      : super(
          Config(
            'canlifalImageCache',
            stalePeriod: const Duration(days: 30),
            maxNrOfCacheObjects: 600,
          ),
        );

  static final CanlifalImageCacheManager instance = CanlifalImageCacheManager._();
}
