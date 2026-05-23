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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/webview/canlifal_cookie_sync.dart';
import '../providers/auth_providers.dart';

/// Google OAuth — önce güvenli tarayıcı; çerezler gizli WebView + Dio ile senkron.
class GoogleAuthWebPage extends ConsumerStatefulWidget {
  const GoogleAuthWebPage({super.key});

  @override
  ConsumerState<GoogleAuthWebPage> createState() => _GoogleAuthWebPageState();
}

class _GoogleAuthWebPageState extends ConsumerState<GoogleAuthWebPage> {
  InAppWebViewController? _bridgeController;
  var _bridgeReady = false;
  var _busy = false;
  var _completed = false;

  static const _chromeMobileUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  String get _origin =>
      Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');

  static String _oauthStartUrl({String? callbackUrl}) {
    final o = Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');
    final base = '$o${ApiEndpoints.authSignInGoogle}';
    if (callbackUrl == null || callbackUrl.isEmpty) return base;
    return '$base?callbackUrl=${Uri.encodeComponent(callbackUrl)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOAuth());
  }

  Future<void> _startOAuth() async {
    if (kIsWeb || _busy || _completed) return;
    final jar = ref.read(cookieJarProvider);
    await applyPersistCookiesToWebView(jar, Env.siteOrigin);
    if (!mounted) return;
    setState(() => _bridgeReady = true);
  }

  Future<void> _finishOAuth() async {
    if (_completed || _busy) return;
    setState(() => _busy = true);
    try {
      final jar = ref.read(cookieJarProvider);
      final storage = ref.read(tokenStorageProvider);

      for (var attempt = 0; attempt < 5; attempt++) {
        await persistWebViewCookiesIntoJar(
          jar,
          Env.siteOrigin,
          webViewController: _bridgeController,
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
        await Future.delayed(Duration(milliseconds: 450 * (attempt + 1)));
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

  /// Chrome Custom Tab — Google OAuth (WebView boş `{}` veya 403 göstermesin).
  Future<void> _oauthViaSecureBrowser() async {
    if (_busy || _completed) return;
    setState(() => _busy = true);
    try {
      final returnTo = '$_origin/api/auth/session';
      final startUrl = _oauthStartUrl(callbackUrl: returnTo);

      final resultUrl = await FlutterWebAuth2.authenticate(
        url: startUrl,
        callbackUrlScheme: 'https',
        options: const FlutterWebAuth2Options(
          preferEphemeral: false,
        ),
      );

      if (_bridgeController != null) {
        final loadUrl =
            resultUrl.startsWith('https') ? resultUrl : returnTo;
        await _bridgeController!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(loadUrl),
            headers: const {'Accept': 'text/html'},
          ),
        );
        await Future.delayed(const Duration(milliseconds: 900));
        await _bridgeController!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(returnTo),
            headers: const {'Accept': 'application/json'},
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
      }

      await _finishOAuth();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('CANCELED')
                  ? 'Google girişi iptal edildi.'
                  : 'Google girişi başarısız. Tekrar deneyin.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Google ile giriş'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _busy ? null : () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _oauthViaSecureBrowser,
            child: const Text('Yenile'),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_bridgeReady)
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0.01,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('$_origin/'),
                    headers: const {'Accept': 'text/html'},
                  ),
                  initialSettings: InAppWebViewSettings(
                    userAgent: _chromeMobileUserAgent,
                    javaScriptEnabled: true,
                    thirdPartyCookiesEnabled: true,
                    sharedCookiesEnabled: true,
                  ),
                  onWebViewCreated: (c) {
                    _bridgeController = c;
                    if (!_busy && !_completed) {
                      _oauthViaSecureBrowser();
                    }
                  },
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_circle_rounded,
                    size: 72,
                    color: AppColors.accentPink,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _busy
                        ? 'Google hesabınıza bağlanılıyor…'
                        : 'Güvenli tarayıcıda Google girişi açılacak',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hesabınızı seçtikten sonra uygulamaya otomatik dönersiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.95),
                      height: 1.4,
                    ),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      color: AppColors.accentPink,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
