import 'package:flutter/material.dart';

/// Ana sayfa bölümlerini kademeli yükler — ilk kare hızlı, ağ istekleri yayılır.
class HomeDeferredSection extends StatefulWidget {
  const HomeDeferredSection({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<HomeDeferredSection> createState() => _HomeDeferredSectionState();
}

class _HomeDeferredSectionState extends State<HomeDeferredSection> {
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
      return const SizedBox(height: 1);
    }
    return RepaintBoundary(child: widget.child);
  }
}
