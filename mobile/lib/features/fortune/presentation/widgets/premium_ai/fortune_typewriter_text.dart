import 'package:flutter/material.dart';

/// Daktilo efekti ile metin gösterimi.
class FortuneTypewriterText extends StatefulWidget {
  const FortuneTypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 18),
    this.onComplete,
  });

  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  @override
  State<FortuneTypewriterText> createState() => _FortuneTypewriterTextState();
}

class _FortuneTypewriterTextState extends State<FortuneTypewriterText> {
  var _visible = 0;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  @override
  void didUpdateWidget(covariant FortuneTypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _visible = 0;
      _done = false;
      _tick();
    }
  }

  Future<void> _tick() async {
    if (!mounted || _done) return;
    if (_visible >= widget.text.length) {
      _done = true;
      widget.onComplete?.call();
      return;
    }
    await Future<void>.delayed(widget.charDuration);
    if (!mounted) return;
    setState(() => _visible++);
    _tick();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _visible.clamp(0, widget.text.length));
    return Text(
      shown,
      style: widget.style,
    );
  }
}
