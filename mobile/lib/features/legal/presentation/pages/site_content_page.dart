import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/site_page_providers.dart';

/// CMS sayfası — `GET /api/site-pages/{slug}` HTML içeriği.
class SiteContentPage extends ConsumerStatefulWidget {
  const SiteContentPage({
    super.key,
    required this.slug,
    required this.title,
    this.fallbackUrl,
  });

  final String slug;
  final String title;
  final String? fallbackUrl;

  @override
  ConsumerState<SiteContentPage> createState() => _SiteContentPageState();
}

class _SiteContentPageState extends ConsumerState<SiteContentPage> {
  WebViewController? _controller;
  var _loading = true;

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(sitePageProvider(widget.slug));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: widget.title,
          body: pageAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _errorBody(),
            data: (page) {
              if (page == null || page.html.trim().isEmpty) {
                return _errorBody();
              }
              _ensureWebView(page.html);
              return Stack(
                children: [
                  if (_controller != null)
                    WebViewWidget(controller: _controller!),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _ensureWebView(String html) {
    if (_controller != null) return;
    final wrapped = '''
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body { font-family: sans-serif; padding: 16px; line-height: 1.55; color: #1a1a1a; }
  h1,h2,h3 { color: #111; }
  a { color: #7c3aed; }
</style>
</head><body>$html</body></html>
''';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(wrapped);
  }

  Widget _errorBody() {
    final url = widget.fallbackUrl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'Sayfa yüklenemedi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (url != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Web\'de aç'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
