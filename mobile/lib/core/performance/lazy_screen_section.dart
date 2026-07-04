import 'package:flutter/material.dart';

import 'widget_perf.dart';

/// Ekran açıldıktan sonra bölümü gecikmeli mount eder — API isteklerini sıraya sokar.
class LazyScreenSection extends StatefulWidget {
  const LazyScreenSection({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.placeholder,
    this.repaintIsolate = true,
  });

  final Widget child;
  final Duration delay;
  final Widget? placeholder;
  /// Profil gibi ekranlarda false — RepaintBoundary raster hayaleti önlenir.
  final bool repaintIsolate;

  @override
  State<LazyScreenSection> createState() => _LazyScreenSectionState();
}

class _LazyScreenSectionState extends State<LazyScreenSection> {
  var _ready = false;
  CancellableDelay? _delay;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ready = true;
      return;
    }
    _delay = WidgetPerf.delay(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    if (widget.repaintIsolate) {
      return RepaintBoundary(child: widget.child);
    }
    return widget.child;
  }
}

/// Liste / tam ekran içerik — provider watch öncesi kısa gecikme.
class LazyScreenGate extends StatefulWidget {
  const LazyScreenGate({
    super.key,
    required this.delay,
    required this.placeholder,
    required this.builder,
  });

  final Duration delay;
  final Widget placeholder;
  final Widget Function(BuildContext context) builder;

  @override
  State<LazyScreenGate> createState() => _LazyScreenGateState();
}

class _LazyScreenGateState extends State<LazyScreenGate> {
  var _ready = false;
  CancellableDelay? _delay;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ready = true;
      return;
    }
    _delay = WidgetPerf.delay(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return widget.placeholder;
    return widget.builder(context);
  }
}
