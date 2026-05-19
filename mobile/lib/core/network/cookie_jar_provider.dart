import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [main] içinde `PersistCookieJar` ile override edilir.
final cookieJarProvider = Provider<CookieJar>((ref) {
  throw StateError(
    'CookieJar başlatılmadı. main() içinde ProviderScope(overrides: [cookieJarProvider.overrideWithValue(...)]) ekleyin.',
  );
});
