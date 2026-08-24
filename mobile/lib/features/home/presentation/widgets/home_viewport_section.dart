import 'package:flutter/material.dart';

import '../../../../core/performance/scroll_perf.dart';

/// Ana sayfa bölümünü viewport yakınına gelince mount eder — erken API yükünü azaltır.
class HomeViewportSection extends StatefulWidget {
  const HomeViewportSection({
    super.key,
    required this.child,
    this.preloadExtent = ScrollPerf.feedCacheExtent,
    this.estimatedHeight = 120,
    this.placeholder,
  });

  final Widget child;
  final double preloadExtent;
  final double estimatedHeight;
  final Widget? placeholder;

  @override
  State<HomeViewportSection> createState() => _HomeViewportSectionState();
}

class _HomeViewportSectionState extends State<HomeViewportSection> {
  final _anchorKey = GlobalKey();
  ScrollPosition? _scrollPosition;
  var _mounted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _scrollPosition) return;
    _scrollPosition?.removeListener(_evaluateVisibility);
    _scrollPosition = position;
    _scrollPosition?.addListener(_evaluateVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateVisibility());
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_evaluateVisibility);
    super.dispose();
  }

  bool _isNearViewport() {
    final ctx = _anchorKey.currentContext;
    if (ctx == null) return false;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;

    final top = renderObject.localToGlobal(Offset.zero).dy;
    final bottom = top + renderObject.size.height;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final preload = widget.preloadExtent;

    return bottom >= -preload && top <= screenHeight + preload;
  }

  void _evaluateVisibility() {
    if (!mounted || _mounted) return;
    if (_isNearViewport()) {
      setState(() => _mounted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mounted) return widget.child;

    return widget.placeholder ??
        SizedBox(
          key: _anchorKey,
          height: widget.estimatedHeight,
        );
  }
}
