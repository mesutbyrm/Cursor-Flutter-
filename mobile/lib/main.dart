import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/bootstrap/app_deferred_bootstrap.dart';
import 'core/bootstrap/app_startup_log.dart';
import 'core/bootstrap/storage_deferred_init.dart';
import 'core/network/cookie_jar_provider.dart';
import 'core/performance/app_perf_metrics.dart';
import 'features/voice_hub/data/services/voice_room_debug_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppPerfMetrics.mark('cold_start');
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 100 << 20;
  AppStartupLog.log('main() begin');

  // Release'de hata detayı gösterme; debug'da teşhis için bırak.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final debug = kDebugMode;
    final msg = details.exceptionAsString();
    return Material(
      color: const Color(0xFF1A0808),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bug_report_rounded,
                        color: Color(0xFFFF6E6E), size: 20),
                    SizedBox(width: 8),
                    Text('Bir bölüm yüklenemedi',
                        style: TextStyle(
                            color: Color(0xFFFF9E9E),
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ],
                ),
                if (debug) ...[
                  const SizedBox(height: 8),
                  Text(
                    msg,
                    style: const TextStyle(
                        color: Color(0xCCFFFFFF), fontSize: 11, height: 1.4),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lütfen sayfayı yenileyin veya uygulamayı yeniden başlatın.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  };

  GoogleFonts.config.allowRuntimeFetching = false;

  AppStartupLog.log('cookie jar init begin');
  final supportDir = await getApplicationSupportDirectory();
  final jar = PersistCookieJar(
    storage: FileStorage('${supportDir.path}/canlifal_cookies'),
    persistSession: true,
  );
  await jar.forceInit();
  AppStartupLog.log('cookie jar init done');
  AppPerfMetrics.end('cold_start');

  runZonedGuarded(
    () {
      AppStartupLog.log('runApp');
      runApp(
        ProviderScope(
          overrides: [cookieJarProvider.overrideWithValue(jar)],
          child: const CanlifalApp(),
        ),
      );
      scheduleDeferredAppBootstrap();
      unawaited(runDeferredStorageInit());
    },
    (error, stack) => VoiceRoomDebugLog.recordZoneError(error, stack),
  );
}
