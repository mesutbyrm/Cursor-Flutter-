import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/admin_web_sso_service.dart';
import '../../domain/admin_web_config.dart';
import '../providers/admin_web_access_provider.dart';

/// Tam ekran mobil admin paneli — WebView + JWT SSO.
class AdminWebPanelPage extends ConsumerStatefulWidget {
  const AdminWebPanelPage({super.key});

  @override
  ConsumerState<AdminWebPanelPage> createState() => _AdminWebPanelPageState();
}

class _AdminWebPanelPageState extends ConsumerState<AdminWebPanelPage> {
  WebViewController? _controller;
  var _loading = true;
  var _progress = 0.0;
  var _loginWall = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!ref.read(adminWebAccessProvider)) return;
    try {
      final sso = AdminWebSsoService(
        tokenStorage: ref.read(tokenStorageProvider),
        cookieJar: ref.read(cookieJarProvider),
        dio: ref.read(dioProvider),
      );
      final payload = await sso.prepareSession();
      await _initWebView(payload);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _initWebView(AdminWebSsoPayload payload) async {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);
    final platform = controller.platform;

    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
      await platform.setOnShowFileSelector(_onAndroidFileSelector);
    }

    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0xFF0D0D12));
    await controller.addJavaScriptChannel(
      'CanlifalAdminBridge',
      onMessageReceived: _onBridgeMessage,
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p / 100);
        },
        onPageStarted: (url) {
          if (mounted) {
            setState(() {
              _loading = true;
              _loginWall = AdminWebConfig.isLoginPath(Uri.parse(url));
            });
          }
        },
        onPageFinished: (url) async {
          if (mounted) {
            setState(() {
              _loading = false;
              _loginWall = AdminWebConfig.isLoginPath(Uri.parse(url));
            });
          }
          await _injectTokenHelpers(payload.accessToken);
        },
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (uri.scheme == 'http') {
            return NavigationDecision.prevent;
          }
          if (!AdminWebConfig.isAllowedNavigation(uri)) {
            unawaited(_openExternal(uri));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onUrlChange: (change) {
          final url = change.url;
          if (url == null) return;
          if (mounted) {
            setState(() {
              _loginWall = AdminWebConfig.isLoginPath(Uri.parse(url));
            });
          }
        },
      ),
    );

    _controller = controller;
    if (mounted) setState(() {});

    await controller.loadHtmlString(
      payload.bootstrapHtml,
      baseUrl: AdminWebConfig.origin,
    );
  }

  Future<void> _injectTokenHelpers(String token) async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final js = '''
(function(t){
  try{localStorage.setItem('canlifal_mobile_access_token',t);}catch(e){}
  try{document.cookie='canlifal_mobile_jwt='+encodeURIComponent(t)+';path=/;secure;samesite=lax';}catch(e){}
})(${_jsString(token)});
''';
    try {
      await ctrl.runJavaScript(js);
    } catch (_) {}
  }

  String _jsString(String s) =>
      "'${s.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'";

  void _onBridgeMessage(JavaScriptMessage message) {
    final msg = message.message.trim();
    if (msg == 'scan_qr') {
      unawaited(_scanQr());
    } else if (msg.startsWith('copy:')) {
      Clipboard.setData(ClipboardData(text: msg.substring(5)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Panoya kopyalandı')),
        );
      }
    }
  }

  Future<List<String>> _onAndroidFileSelector(
    FileSelectorParams params,
  ) async {
    final accept = params.acceptTypes.join(',').toLowerCase();
    final allowsMultiple = params.mode == FileSelectorMode.openMultiple;

    if (accept.contains('image') || accept.isEmpty) {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (source == null) return [];

      if (source == ImageSource.camera) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) return [];
      }

      if (allowsMultiple && source == ImageSource.gallery) {
        final files = await ImagePicker().pickMultiImage(imageQuality: 90);
        return files.map((f) => f.path).where((p) => p.isNotEmpty).toList();
      }

      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null) return [];
      return [file.path];
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowsMultiple,
      type: FileType.custom,
      allowedExtensions: _extensionsFromAccept(accept),
    );
    if (result == null) return [];
    return result.paths.whereType<String>().toList();
  }

  List<String>? _extensionsFromAccept(String accept) {
    if (accept.contains('pdf')) return ['pdf'];
    if (accept.contains('sheet') || accept.contains('excel')) {
      return ['xls', 'xlsx', 'csv'];
    }
    return null;
  }

  Future<void> _scanQr() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;
    await _controller?.runJavaScript(
      "window.dispatchEvent(new CustomEvent('canlifal-qr-picked',{detail:${_jsString(file.path)}}));",
    );
  }

  Future<void> _openExternal(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Açılamadı: $uri')),
      );
    }
  }

  Future<void> _reload() async {
    final ctrl = _controller;
    if (ctrl == null) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
      await _bootstrap();
      return;
    }
    setState(() => _loading = true);
    await ctrl.reload();
  }

  Future<bool> _handleBack() async {
    final ctrl = _controller;
    if (ctrl != null && await ctrl.canGoBack()) {
      await ctrl.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final allowed = ref.watch(adminWebAccessProvider);
    if (!allowed) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message:
                  'Yönetim paneli yalnızca Admin ve Süper Admin hesapları içindir.',
              actionLabel: 'Geri',
              action: () => context.pop(),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _handleBack()) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        body: SafeArea(
          child: Column(
            children: [
              _AdminWebToolbar(
                loading: _loading,
                progress: _progress,
                onClose: () => context.pop(),
                onRefresh: _reload,
                onNativeAdmin: () => context.push('/admin/panel'),
              ),
              if (_loginWall)
                MaterialBanner(
                  content: const Text(
                    'Web oturumu kurulamadı. Yerel admin paneline geçebilir veya yenileyebilirsiniz.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.push('/admin/panel'),
                      child: const Text('Yerel panel'),
                    ),
                    TextButton(onPressed: _reload, child: const Text('Yenile')),
                  ],
                ),
              Expanded(
                child: _errorMessage != null
                    ? _ErrorPane(
                        message: '$_errorMessage',
                        onRetry: _bootstrap,
                      )
                    : Stack(
                        children: [
                          if (_controller != null)
                            WebViewWidget(controller: _controller!),
                          if (_loading)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminWebToolbar extends StatelessWidget {
  const _AdminWebToolbar({
    required this.loading,
    required this.progress,
    required this.onClose,
    required this.onRefresh,
    required this.onNativeAdmin,
  });

  final bool loading;
  final double progress;
  final VoidCallback onClose;
  final VoidCallback onRefresh;
  final VoidCallback onNativeAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: onClose,
              ),
              const Expanded(
                child: Text(
                  'Yönetim Paneli',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Yerel admin',
                icon: const Icon(Icons.dashboard_customize_outlined,
                    color: Colors.white70),
                onPressed: onNativeAdmin,
              ),
              IconButton(
                icon: Icon(
                  loading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                  color: Colors.white70,
                ),
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
        if (loading && progress > 0 && progress < 1)
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: Colors.white12,
            color: const Color(0xFFB832FF),
          ),
      ],
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
