import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/webview/canlifal_cookie_sync.dart';
import '../providers/auth_providers.dart';

/// Google OAuth — yalnızca hesap seçimi; site gezintisi yok, oturum otomatik aktarılır.
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
  double _progress = 0;
  WebUri? _startUri;

  static String _oauthStartUrl() {
    final o = Env.siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');
    return '$o${ApiEndpoints.authSignInGoogle}';
  }

  static bool _allowInWebView(WebUri? uri) {
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return true;
    if (host.contains('canlifal.com')) return true;
    if (host.contains('google.com') ||
        host.contains('gstatic.com') ||
        host.contains('googleusercontent.com')) {
      return true;
    }
    return false;
  }

  static bool _oauthFinished(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!host.contains('canlifal.com')) return false;
    final path = uri.path;
    if (path.contains('/api/auth/signin')) return false;
    if (path.contains('/api/auth/callback')) return true;
    if (!path.contains('/api/auth/')) return true;
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
    if (mounted) {
      setState(() {
        _startUri = WebUri(_oauthStartUrl());
        _ready = true;
      });
    }
  }

  Future<void> _finishOAuth() async {
    if (_completed || _busy) return;
    setState(() => _busy = true);
    try {
      final jar = ref.read(cookieJarProvider);
      await persistWebViewCookiesIntoJar(
        jar,
        Env.siteOrigin,
        webViewController: _controller,
      );
      await ref.read(authControllerProvider.notifier).refreshMe();
      if (!mounted) return;
      final me = ref.read(authControllerProvider).valueOrNull;
      if (me != null) {
        _completed = true;
        context.go('/feed');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google oturumu alınamadı. Tekrar deneyin.'),
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

  void _onUrlMaybeComplete(WebUri? webUri) {
    if (_completed || webUri == null) return;
    final uri = Uri.tryParse(webUri.toString());
    if (uri == null || !_oauthFinished(uri)) return;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && !_completed) _finishOAuth();
    });
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
        title: const Text('Google ile giriş'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _busy ? null : () => context.pop(),
        ),
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
          if (_ready && _startUri != null)
            InAppWebView(
              initialUrlRequest: URLRequest(url: _startUri),
              initialSettings: InAppWebViewSettings(
                isInspectable: kDebugMode,
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                useHybridComposition: true,
              ),
              onWebViewCreated: (c) => _controller = c,
              onProgressChanged: (_, p) {
                if (mounted) setState(() => _progress = p / 100.0);
              },
              onLoadStop: (_, uri) => _onUrlMaybeComplete(uri),
              onUpdateVisitedHistory: (_, uri, _) => _onUrlMaybeComplete(uri),
              shouldOverrideUrlLoading: (_, action) async {
                final uri = action.request.url;
                if (_allowInWebView(uri)) {
                  return NavigationActionPolicy.ALLOW;
                }
                return NavigationActionPolicy.CANCEL;
              },
            )
          else
            const Center(child: CircularProgressIndicator()),
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
