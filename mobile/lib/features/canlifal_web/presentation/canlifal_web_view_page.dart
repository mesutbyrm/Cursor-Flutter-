import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/native_site_routes.dart';
import '../../../core/theme/app_theme_extensions.dart';

/// WebView kaldırıldı — site yolları native Flutter ekranlarına yönlendirilir.
class CanlifalWebViewPage extends StatelessWidget {
  const CanlifalWebViewPage({
    super.key,
    this.relativePath = '/',
    this.title,
  });

  final String relativePath;
  final String? title;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      openNativeSitePath(context, relativePath);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'CanlıFal')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'İçerik native uygulama ekranında açılıyor…',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class CanlifalWebRoute {
  static String location({
    required String relativePath,
    String? title,
  }) {
    final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    final q = title != null && title.isNotEmpty
        ? '?title=${Uri.encodeComponent(title)}'
        : '';
    return '/canlifal-web?path=${Uri.encodeComponent(path)}$q';
  }

  static GoRoute route() {
    return GoRoute(
      path: '/canlifal-web',
      builder: (context, state) => fromState(state),
    );
  }

  static CanlifalWebViewPage fromState(GoRouterState state) {
    final path = state.uri.queryParameters['path'] ?? '/';
    final title = state.uri.queryParameters['title'];
    return CanlifalWebViewPage(
      relativePath: path,
      title: title,
    );
  }
}
