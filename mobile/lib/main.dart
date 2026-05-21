import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/network/cookie_jar_provider.dart';
import 'core/storage/local_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await LocalCache.init();
  } catch (e) {
    debugPrint('LocalCache init failed: $e');
  }

  await FirebaseBootstrap.init();

  // Ağ yokken font indirme bazı cihazlarda açılışta çökme yapabiliyor.
  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
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
      runApp(
        ProviderScope(
          overrides: [cookieJarProvider.overrideWithValue(jar!)],
          child: const CanlifalApp(),
        ),
      );
    },
    (error, stack) => debugPrint('Zone error: $error\n$stack'),
  );
}
