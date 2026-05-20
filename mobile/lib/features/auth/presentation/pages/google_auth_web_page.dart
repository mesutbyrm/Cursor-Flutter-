import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/webview/canlifal_cookie_sync.dart';
import '../providers/auth_providers.dart';

/// Google OAuth — güvenli tarayıcı (403 önleme) + oturum çerezlerini uygulamaya aktarma.
class GoogleAuthWebPage extends ConsumerStatefulWidget {
  const GoogleAuthWebPage({super.key});

  @override
  ConsumerState<GoogleAuthWebPage> createState() => _GoogleAuthWebPageState();
}

class _GoogleAuthWebPageState extends ConsumerState<GoogleAuthWebPage> {
  InAppWebViewController? _controller;
  var _ready = false;
  var _busy = false;
  var _completed = false;
  var _useSecureBrowser = false;
  double _progress = 0;
  WebUri? _startUri;

  /// Google, gömülü WebView user-agent'ını engeller (403 disallowed_useragent).
  static const _chromeMobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  static String _oauthStartUrl({String? callbackUrl}) {
    final o = Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');
    final base = '$o${ApiEndpoints.authSignInGoogle}';
    if (callbackUrl == null || callbackUrl.isEmpty) return base;
    return '$base?callbackUrl=${Uri.encodeComponent(callbackUrl)}';
  }

  static bool _isGoogleHost(String host) {
    return host.contains('google.com') ||
        host.contains('gstatic.com') ||
        host.contains('googleusercontent.com') ||
        host.contains('accounts.google.');
  }

  static bool _isCanlifalAuthPath(String path) {
    return path.startsWith('/api/auth/');
  }

  static bool _oauthCallbackReached(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!host.contains('canlifal.com')) return false;
    final path = uri.path;
    if (path.contains('/api/auth/callback')) return true;
    if (path == '/api/auth/session' || path.endsWith('/api/auth/session')) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prime());
  }

  Future<void> _prime() async {
    if (kIsWeb) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    final jar = ref.read(cookieJarProvider);
    await applyPersistCookiesToWebView(jar, Env.siteOrigin);
    if (!mounted) return;
    setState(() {
      _startUri = WebUri(_oauthStartUrl());
      _ready = true;
    });
    // Google OAuth WebView’da 403 verir; doğrudan güvenli tarayıcı (Custom Tab).
    await _oauthViaSecureBrowser();
  }

  Future<bool> _hasNextAuthSessionCookie() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri(Env.siteOrigin),
      webViewController: _controller,
    );
    return cookies.any(
      (c) =>
          c.name.contains('session-token') ||
          c.name == 'next-auth.session-token' ||
          c.name.startsWith('__Secure-next-auth'),
    );
  }

  Future<void> _finishOAuth({bool allowWhileBusy = false}) async {
    if (_completed || (_busy && !allowWhileBusy)) return;
    setState(() => _busy = true);
    try {
      final jar = ref.read(cookieJarProvider);
      final storage = ref.read(tokenStorageProvider);

      for (var attempt = 0; attempt < 4; attempt++) {
        await persistWebViewCookiesIntoJar(
          jar,
          Env.siteOrigin,
          webViewController: _controller,
        );
        await storage.writeTokens(
          access: TokenStorage.sessionCookieMarker,
          refresh: null,
        );
        await ref.read(authControllerProvider.notifier).refreshMe();
        if (!mounted) return;
        if (ref.read(authControllerProvider).valueOrNull != null) {
          _completed = true;
          context.go('/feed');
          return;
        }
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google oturumu alınamadı. Tekrar deneyin veya e-posta ile giriş yapın.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scheduleFinish() {
    if (_completed) return;
    Future.delayed(const Duration(milliseconds: 450), () async {
      if (!mounted || _completed) return;
      if (await _hasNextAuthSessionCookie()) {
        await _finishOAuth();
      }
    });
  }

  void _onUrlMaybeComplete(WebUri? webUri) {
    if (_completed || webUri == null) return;
    final uri = Uri.tryParse(webUri.toString());
    if (uri == null) return;
    if (_oauthCallbackReached(uri)) {
      _scheduleFinish();
      return;
    }
    if (uri.host.toLowerCase().contains('canlifal.com') &&
        !_isCanlifalAuthPath(uri.path)) {
      _scheduleFinish();
    }
  }

  /// Sistem tarayıcısı (Chrome Custom Tab) — Google 403 için yedek.
  Future<void> _oauthViaSecureBrowser() async {
    if (_busy || _completed) return;
    setState(() {
      _busy = true;
      _useSecureBrowser = true;
    });
    try {
      final returnTo =
          '${Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '')}/api/auth/session';
      final startUrl = _oauthStartUrl(callbackUrl: returnTo);

      final resultUrl = await FlutterWebAuth2.authenticate(
        url: startUrl,
        callbackUrlScheme: 'https',
        options: const FlutterWebAuth2Options(
          preferEphemeral: false,
        ),
      );

      if (mounted) {
        setState(() => _useSecureBrowser = false);
      }
      if (_controller != null && resultUrl.startsWith('https')) {
        await _controller!.loadUrl(
          urlRequest: URLRequest(url: WebUri(resultUrl)),
        );
        await Future.delayed(const Duration(milliseconds: 900));
      } else if (_controller != null) {
        await _controller!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(
              '${Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '')}/api/auth/session',
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 900));
      }
      await _finishOAuth(allowWhileBusy: true);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('CANCELED')
                  ? 'Google girişi iptal edildi.'
                  : 'Güvenli tarayıcı ile giriş başarısız: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _useSecureBrowser = false;
        });
      }
    }
  }

  void _onReceivedError(WebUri? uri, String? description) {
    final d = (description ?? '').toLowerCase();
    final u = uri?.toString().toLowerCase() ?? '';
    if (d.contains('disallowed_useragent') ||
        u.contains('accounts.google.com') && d.contains('403')) {
      _oauthViaSecureBrowser();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Google ile giriş')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Google girişi yalnızca mobil uygulamada desteklenir.'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      appBar: AppBar(
        title: const Text('Google hesabını seç'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _busy ? null : () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _oauthViaSecureBrowser,
            child: const Text('Tarayıcı'),
          ),
        ],
        bottom: _progress > 0 && _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  color: AppDesign.accentPink,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          if (_ready)
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0.01,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      '${Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '')}/api/auth/session',
                    ),
                  ),
                  initialSettings: InAppWebViewSettings(
                    userAgent: _chromeMobileUserAgent,
                    javaScriptEnabled: true,
                    thirdPartyCookiesEnabled: true,
                    useShouldOverrideUrlLoading: true,
                  ),
                  onWebViewCreated: (c) => _controller = c,
                  onLoadStop: (_, uri) => _onUrlMaybeComplete(uri),
                  shouldOverrideUrlLoading: (_, action) async {
                    final uri = action.request.url;
                    if (uri == null) return NavigationActionPolicy.CANCEL;
                    final u = Uri.tryParse(uri.toString());
                    if (u == null) return NavigationActionPolicy.CANCEL;
                    final host = u.host.toLowerCase();
                    if (_isGoogleHost(host)) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    if (host.contains('canlifal.com')) {
                      if (_isCanlifalAuthPath(u.path)) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      _scheduleFinish();
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.CANCEL;
                  },
                ),
              ),
            ),
          if (_useSecureBrowser || !_ready)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppDesign.accentPink),
                  SizedBox(height: 16),
                  Text('Güvenli tarayıcıda Google girişi açılıyor…'),
                ],
              ),
            ),
          if (_busy)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppDesign.accentPink),
                    SizedBox(height: 16),
                    Text(
                      'Hesabınıza bağlanılıyor…',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
