import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/bootstrap/app_startup_log.dart';
import 'features/voice_hub/data/services/voice_room_debug_log.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/network/cookie_jar_provider.dart';
import 'core/onesignal/onesignal_bootstrap.dart';
import 'core/storage/local_cache.dart';
import 'core/storage/theme_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStartupLog.log('main() begin');

  try {
    await LocalCache.init();
  } catch (e) {
    debugPrint('LocalCache init failed: $e');
  }

  try {
    await ThemePreferences.init();
  } catch (e) {
    debugPrint('ThemePreferences init failed: $e');
  }

  await OneSignalBootstrap.init();
  AppStartupLog.log('OneSignal init done');
  await FirebaseBootstrap.init();
  AppStartupLog.log('Firebase init done');

  // Ağ yokken font indirme bazı cihazlarda açılışta çökme yapabiliyor.
  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    VoiceRoomDebugLog.recordFlutterError(
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    VoiceRoomDebugLog.recordPlatformError(error, stack);
    return true;
  };

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
    },
    (error, stack) => VoiceRoomDebugLog.recordZoneError(error, stack),
  );
}
