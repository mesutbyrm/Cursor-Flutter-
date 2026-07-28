import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

import '../offline/api_cache_store.dart';
import '../storage/local_cache.dart';
import '../storage/theme_preferences.dart';
import 'app_startup_log.dart';

/// Hive, tema tercihi, API önbelleği ve çerez yükleme — runApp sonrası.
Future<void> runDeferredStorageInit(PersistCookieJar jar) async {
  try {
    await Future.wait<void>([
      LocalCache.init().catchError((Object e) {
        debugPrint('LocalCache deferred init failed: $e');
      }),
      ThemePreferences.init().catchError((Object e) {
        debugPrint('ThemePreferences deferred init failed: $e');
      }),
      ApiCacheStore.init().catchError((Object e) {
        debugPrint('ApiCacheStore deferred init failed: $e');
      }),
      jar.forceInit().catchError((Object e) {
        debugPrint('Cookie jar forceInit failed: $e');
      }),
    ]);
    AppStartupLog.log('deferred storage init done');
  } catch (e) {
    debugPrint('Deferred storage init failed: $e');
  }
}
