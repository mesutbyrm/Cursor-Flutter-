import 'package:flutter/material.dart';

/// Ekran açıldıktan sonra bölümü gecikmeli mount eder — API isteklerini sıraya sokar.
class LazyScreenSection extends StatefulWidget {
  const LazyScreenSection({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.placeholder,
  });

  final Widget child;
  final Duration delay;
  final Widget? placeholder;

  @override
  State<LazyScreenSection> createState() => _LazyScreenSectionState();
}

class _LazyScreenSectionState extends State<LazyScreenSection> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ready = true;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return RepaintBoundary(child: widget.child);
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

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ready = true;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return widget.placeholder;
    return widget.builder(context);
  }
}
