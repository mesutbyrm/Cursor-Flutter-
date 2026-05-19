import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/network/cookie_jar_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDir = await getApplicationSupportDirectory();
  final jar = PersistCookieJar(
    storage: FileStorage('${supportDir.path}/canlifal_cookies'),
    persistSession: true,
  );
  await jar.forceInit();

  runApp(
    ProviderScope(
      overrides: [cookieJarProvider.overrideWithValue(jar)],
      child: const CanlifalApp(),
    ),
  );
}
