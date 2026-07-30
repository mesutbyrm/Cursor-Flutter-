import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lazy_cookie_jar.dart';

/// Tek çerez jar — [LazyCookieJar] ile soğuk açılışta bloklanmaz.
final cookieJarProvider = Provider<CookieJar>((ref) {
  return LazyCookieJar.instance;
});
