import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/network/cookie_jar_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/webview/canlifal_cookie_sync.dart';
import '../../live/presentation/widgets/live_gift_sheet.dart';

/// canlifal.com sayfasını uygulama içinde açar; oturum çerezleri WebView’a kopyalanır
/// (sesli oda TRTC ve canlı yayın oynatıcı için gerekli).
class CanlifalWebViewPage extends ConsumerStatefulWidget {
  const CanlifalWebViewPage({
    super.key,
    required this.relativePath,
    required this.title,
    this.streamIdForGifts,
  });

  /// Örn. `/sohbet/sohbet` veya `/sohbet/video?watch=...`
  final String relativePath;
  final String title;
  final String? streamIdForGifts;

  @override
  ConsumerState<CanlifalWebViewPage> createState() => _CanlifalWebViewPageState();
}

class _CanlifalWebViewPageState extends ConsumerState<CanlifalWebViewPage> {
  var _ready = false;
  WebUri? _webUri;
  double _progress = 0;
  InAppWebViewController? _controller;
  late final PullToRefreshController _pull;

  static String _fullUrl(String origin, String path) {
    final o = origin.trim().replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$o$p';
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
                    if (uri == null) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    final host = uri.host;
                    if (host.contains('canlifal.com') || host.isEmpty) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

/// `go_router` query: `path`, `title`, isteğe bağlı `streamId` (hediye paneli).
class CanlifalWebRoute {
  static String location({
    required String relativePath,
    required String title,
    String? streamIdForGifts,
  }) {
    return Uri(
      path: '/canlifal-web',
      queryParameters: <String, String>{
        'path': relativePath,
        'title': title,
        if (streamIdForGifts != null && streamIdForGifts.isNotEmpty)
          'streamId': streamIdForGifts,
      },
    ).toString();
  }

  static CanlifalWebViewPage fromState(GoRouterState state) {
    final path = state.uri.queryParameters['path'] ?? '/';
    final title = state.uri.queryParameters['title'] ?? 'Canlifal';
    final sid = state.uri.queryParameters['streamId'];
    return CanlifalWebViewPage(
      relativePath: path.startsWith('/') ? path : '/$path',
      title: title,
      streamIdForGifts: sid,
    );
  }
}
