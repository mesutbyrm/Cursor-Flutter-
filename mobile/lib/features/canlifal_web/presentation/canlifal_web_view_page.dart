import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cookie_jar_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/webview/canlifal_cookie_sync.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../live/presentation/widgets/live_gift_sheet.dart';

/// canlifal.com sayfasını uygulama içinde açar; oturum çerezleri WebView’a kopyalanır
/// (sesli oda TRTC ve canlı yayın oynatıcı için gerekli).
class CanlifalWebViewPage extends ConsumerStatefulWidget {
  const CanlifalWebViewPage({
    super.key,
    required this.relativePath,
    required this.title,
    this.streamIdForGifts,
    this.sessionImportMode = false,
  });

  /// Örn. `/sohbet/sohbet` veya `/sohbet/video?watch=...`
  final String relativePath;
  final String title;
  final String? streamIdForGifts;

  /// Google OAuth sonrası WebView çerezlerini Dio kavanozuna aktarmak için araç çubuğu gösterir.
  final bool sessionImportMode;

  @override
  ConsumerState<CanlifalWebViewPage> createState() => _CanlifalWebViewPageState();
}

class _CanlifalWebViewPageState extends ConsumerState<CanlifalWebViewPage> {
  var _ready = false;
  WebUri? _webUri;
  double _progress = 0;
  InAppWebViewController? _controller;
  var _importBusy = false;
  late final PullToRefreshController _pull;

  static String _fullUrl(String origin, String path) {
    final o = origin.trim().replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$o$p';
  }

  static bool _allowInWebView(WebUri? uri) {
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return true;
    if (host.contains('canlifal.com')) return true;
    // Google OAuth zinciri WebView içinde kalmalı; aksi halde oturum çerezleri uygulamaya dönmez.
    if (host.contains('google.com') ||
        host.contains('gstatic.com') ||
        host.contains('googleusercontent.com')) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _pull = PullToRefreshController(
      settings: PullToRefreshSettings(color: AppTheme.accent),
      onRefresh: () async {
        await _controller?.reload();
        await _pull.endRefreshing();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _prime());
  }

  Future<void> _prime() async {
    if (kIsWeb) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    final jar = ref.read(cookieJarProvider);
    await applyPersistCookiesToWebView(jar, Env.siteOrigin);
    final url = _fullUrl(Env.siteOrigin, widget.relativePath);
    if (mounted) {
      setState(() {
        _webUri = WebUri(url);
        _ready = true;
      });
    }
    if (widget.sessionImportMode && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google ile giriş yaptıktan sonra üstteki «Oturumu aktar» ile uygulamaya dönün.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _importSessionFromWebView() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _importBusy = true);
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
        context.go('/feed');
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Oturum alınamadı. Google girişini tamamlayıp tekrar deneyin.',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _importBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final url = _fullUrl(Env.siteOrigin, widget.relativePath);
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Web platformunda yerleşik oynatıcı kullanılamıyor.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => launchUrl(Uri.parse(url)),
                  child: const Text('Tarayıcıda aç'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.sessionImportMode)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: _importBusy ? null : _importSessionFromWebView,
                child: _importBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Oturumu aktar'),
              ),
            ),
        ],
        bottom: _progress < 1 && _progress > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: !_ready || _webUri == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: _webUri),
                  initialSettings: InAppWebViewSettings(
                    isInspectable: kDebugMode,
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    useHybridComposition: true,
                    useShouldOverrideUrlLoading: true,
                  ),
                  pullToRefreshController: _pull,
                  onWebViewCreated: (c) => _controller = c,
                  onProgressChanged: (c, p) {
                    if (mounted) setState(() => _progress = p / 100.0);
                  },
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                  shouldOverrideUrlLoading: (controller, action) async {
                    final uri = action.request.url;
                    if (_allowInWebView(uri)) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    return NavigationActionPolicy.CANCEL;
                  },
                ),
                if (widget.streamIdForGifts != null &&
                    widget.streamIdForGifts!.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: FloatingActionButton.extended(
                      onPressed: () => showLiveGiftPicker(
                        context,
                        ref,
                        streamId: widget.streamIdForGifts!,
                      ),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: const Text('Hediye'),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// `go_router` query: `path`, `title`, isteğe bağlı `streamId` (hediye paneli), `importSession`.
class CanlifalWebRoute {
  static String location({
    required String relativePath,
    required String title,
    String? streamIdForGifts,
    bool sessionImport = false,
  }) {
    return Uri(
      path: '/canlifal-web',
      queryParameters: <String, String>{
        'path': relativePath,
        'title': title,
        if (streamIdForGifts != null && streamIdForGifts.isNotEmpty)
          'streamId': streamIdForGifts,
        if (sessionImport) 'importSession': '1',
      },
    ).toString();
  }

  static CanlifalWebViewPage fromState(GoRouterState state) {
    final path = state.uri.queryParameters['path'] ?? '/';
    final title = state.uri.queryParameters['title'] ?? 'Canlifal';
    final sid = state.uri.queryParameters['streamId'];
    final import = state.uri.queryParameters['importSession'] == '1';
    return CanlifalWebViewPage(
      relativePath: path.startsWith('/') ? path : '/$path',
      title: title,
      streamIdForGifts: sid,
      sessionImportMode: import,
    );
  }
}
