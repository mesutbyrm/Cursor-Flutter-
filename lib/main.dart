import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CanlifalApp());
}

class CanlifalApp extends StatelessWidget {
  const CanlifalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canlifal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CanlifalHomePage(),
    );
  }
}

class CanlifalHomePage extends StatefulWidget {
  const CanlifalHomePage({super.key});

  @override
  State<CanlifalHomePage> createState() => _CanlifalHomePageState();
}

class _CanlifalHomePageState extends State<CanlifalHomePage> {
  static final List<_Destination> _destinations = <_Destination>[
    _Destination(
      label: 'Ana Sayfa',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      path: '/',
    ),
    _Destination(
      label: 'Videolar',
      icon: Icons.play_circle_outline,
      selectedIcon: Icons.play_circle,
      path: '/videolar',
    ),
    _Destination(
      label: 'Canlı',
      icon: Icons.live_tv_outlined,
      selectedIcon: Icons.live_tv,
      path: '/canli-yayinlar',
    ),
    _Destination(
      label: 'Falcılar',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      path: '/canli-falcilar',
    ),
    _Destination(
      label: 'Fal',
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department,
      path: '/fallar',
    ),
  ];

  late final WebViewController _controller;
  int _currentIndex = 0;
  int _progress = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _handleProgress,
          onPageStarted: _handlePageStarted,
          onPageFinished: _handlePageFinished,
          onWebResourceError: _handleWebResourceError,
          onNavigationRequest: _handleNavigationRequest,
          onUrlChange: (UrlChange change) => _syncDestination(change.url),
        ),
      )
      ..loadRequest(_destinations.first.uri);
  }

  @override
  Widget build(BuildContext context) {
    final _Destination activeDestination = _destinations[_currentIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          await _goBackOrClose();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Canlifal'),
              Text(
                activeDestination.label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Geri',
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
            ),
            IconButton(
              tooltip: 'Yenile',
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    WebViewWidget(controller: _controller),
                    if (_errorMessage != null)
                      _LoadErrorView(
                        message: _errorMessage!,
                        onRetry: _reload,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _openDestination,
          destinations: <Widget>[
            for (final _Destination destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      ),
    );
  }

  void _handleProgress(int progress) {
    if (!mounted) {
      return;
    }

    setState(() {
      _progress = progress;
      _isLoading = progress < 100;
    });
  }

  void _handlePageStarted(String url) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });
    _syncDestination(url);
  }

  void _handlePageFinished(String url) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _progress = 100;
    });
    _syncDestination(url);
  }

  void _handleWebResourceError(WebResourceError error) {
    if (error.isForMainFrame == false || !mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = error.description;
    });
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final Uri? uri = Uri.tryParse(request.url);
    if (uri == null) {
      return NavigationDecision.prevent;
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return NavigationDecision.navigate;
    }

    return NavigationDecision.prevent;
  }

  void _syncDestination(String? url) {
    if (url == null || !mounted) {
      return;
    }

    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final int index = _destinations.indexWhere(
      (_Destination destination) =>
          destination.path != '/' && uri.path.startsWith(destination.path),
    );

    final int nextIndex = index == -1 ? 0 : index;
    if (nextIndex == _currentIndex) {
      return;
    }

    setState(() => _currentIndex = nextIndex);
  }

  Future<void> _openDestination(int index) async {
    if (index == _currentIndex) {
      await _controller.reload();
      return;
    }

    setState(() => _currentIndex = index);
    await _controller.loadRequest(_destinations[index].uri);
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goBackOrClose() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }

    await SystemNavigator.pop();
  }

  Future<void> _reload() async {
    setState(() => _errorMessage = null);
    await _controller.reload();
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  static const String _baseUrl = 'https://canlifal.com';

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;

  Uri get uri => Uri.parse('$_baseUrl$path');
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.wifi_off,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Sayfa yüklenemedi',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
