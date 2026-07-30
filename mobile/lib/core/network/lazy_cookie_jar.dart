import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

import '../bootstrap/app_startup_log.dart';

/// Çerez jar — ilk HTTP isteğinde veya arka planda başlatılır; `main()` bloklanmaz.
class LazyCookieJar implements CookieJar {
  LazyCookieJar._();

  static final LazyCookieJar instance = LazyCookieJar._();

  PersistCookieJar? _jar;
  Future<PersistCookieJar>? _initFuture;
  bool _ignoreExpires = false;

  @override
  bool get ignoreExpires => _jar?.ignoreExpires ?? _ignoreExpires;

  @override
  set ignoreExpires(bool value) {
    _ignoreExpires = value;
    _jar?.ignoreExpires = value;
  }

  Future<PersistCookieJar> _ensure() {
    final existing = _jar;
    if (existing != null) return Future.value(existing);
    return _initFuture ??= _create();
  }

  Future<PersistCookieJar> _create() async {
    AppStartupLog.log('cookie jar init begin (deferred)');
    final supportDir = await getApplicationSupportDirectory();
    final jar = PersistCookieJar(
      storage: FileStorage('${supportDir.path}/canlifal_cookies'),
      persistSession: true,
    );
    await jar.forceInit();
    _jar = jar;
    AppStartupLog.log('cookie jar init done (deferred)');
    return jar;
  }

  /// runApp sonrası arka planda ısıt — ilk web oturumu isteği daha hızlı olur.
  void prewarm() {
    unawaited(_ensure().catchError((Object e) {
      AppStartupLog.log('cookie jar prewarm failed: $e');
      throw e;
    }));
  }

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    return (await _ensure()).loadForRequest(uri);
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    await (await _ensure()).saveFromResponse(uri, cookies);
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    final jar = _jar;
    if (jar == null) return;
    await jar.delete(uri, withDomainSharedCookie);
  }

  @override
  Future<void> deleteAll() async {
    final jar = _jar;
    if (jar == null) return;
    await jar.deleteAll();
  }
}
