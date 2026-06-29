import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/bootstrap/app_deferred_bootstrap.dart';
import 'core/bootstrap/app_startup_log.dart';
import 'core/crash/crash_reporting_bootstrap.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/network/cookie_jar_provider.dart';
import 'core/onesignal/onesignal_bootstrap.dart';
import 'core/offline/api_cache_store.dart';
import 'core/performance/app_perf_metrics.dart';
import 'core/performance/network_perf.dart';
import 'core/storage/local_cache.dart';
import 'core/storage/theme_preferences.dart';
import 'features/voice_hub/data/services/voice_room_debug_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppPerfMetrics.mark('cold_start');
  PaintingBinding.instance.imageCache
    ..maximumSize = 150
    ..maximumSizeBytes = 80 << 20;
  AppStartupLog.log('main() begin');

  try {
    await NetworkPerf.parallel([
      LocalCache.init().catchError((Object e) {
        debugPrint('LocalCache init failed: $e');
      }),
      ThemePreferences.init().catchError((Object e) {
        debugPrint('ThemePreferences init failed: $e');
      }),
      ApiCacheStore.init().catchError((Object e) {
        debugPrint('ApiCacheStore init failed: $e');
      }),
    ]);
  } catch (e) {
    debugPrint('Local storage init failed: $e');
  }

  await OneSignalBootstrap.init();
  AppStartupLog.log('OneSignal init done');
  await FirebaseBootstrap.init();
  AppStartupLog.log('Firebase init done');
  await CrashReportingBootstrap.init();
  AppStartupLog.log('Crash reporting init done');

  GoogleFonts.config.allowRuntimeFetching = false;
  AppPerfMetrics.end('cold_start');

  PersistCookieJar? jar;
  try {
    final supportDir = await getApplicationSupportDirectory();
    jar = PersistCookieJar(
      storage: FileStorage('${supportDir.path}/canlifal_cookies'),
      persistSession: true,
    );
    await jar.forceInit();
  } catch (e) {
    debugPrint('Cookie jar init failed: $e');
    jar = PersistCookieJar();
  }

  runZonedGuarded(
    () {
      AppStartupLog.log('runApp');
      runApp(
        ProviderScope(
          overrides: [cookieJarProvider.overrideWithValue(jar!)],
          child: const CanlifalApp(),
        ),
      );
      scheduleDeferredAppBootstrap();
    },
    (error, stack) => VoiceRoomDebugLog.recordZoneError(error, stack),
  );
}
