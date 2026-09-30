import 'dart:async';

import 'package:flutter/material.dart';

/// Tek `Timer.periodic(1s)` — kalan süre `endsAt - now` (+ isteğe bağlı sunucu sapması).
class PkEndsAtCountdownText extends StatefulWidget {
  const PkEndsAtCountdownText({
    super.key,
    required this.endsAt,
    this.serverNow,
    this.style,
    this.fallbackSeconds,
    this.builder,
  });

  final DateTime? endsAt;
  final DateTime? serverNow;
  final TextStyle? style;
  final int? fallbackSeconds;
  final Widget Function(BuildContext context, int secondsRemaining)? builder;

  @override
  State<PkEndsAtCountdownText> createState() => _PkEndsAtCountdownTextState();
}

class _PkEndsAtCountdownTextState extends State<PkEndsAtCountdownText> {
  final ValueNotifier<int> _seconds = ValueNotifier(0);
  Timer? _timer;
  Duration _clockSkew = Duration.zero;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    _applyClock(widget.endsAt, widget.serverNow, widget.fallbackSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant PkEndsAtCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt ||
        oldWidget.serverNow != widget.serverNow ||
        oldWidget.fallbackSeconds != widget.fallbackSeconds) {
      _applyClock(widget.endsAt, widget.serverNow, widget.fallbackSeconds);
    }
  }

  void _applyClock(DateTime? endsAt, DateTime? serverNow, int? fallbackSeconds) {
    _endsAt = endsAt?.toUtc();
    if (serverNow != null) {
      _clockSkew = serverNow.toUtc().difference(DateTime.now().toUtc());
    }
    _tick();
  }

  void _tick() {
    final end = _endsAt;
    if (end != null) {
      final now = DateTime.now().toUtc().add(_clockSkew);
      final sec = end.difference(now).inSeconds.clamp(0, 86400);
      if (_seconds.value != sec) _seconds.value = sec;
      return;
    }
    final fb = widget.fallbackSeconds;
    if (fb != null && fb >= 0) {
      if (_seconds.value != fb) _seconds.value = fb;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

  static String formatSeconds(int seconds) {
    final s = seconds.clamp(0, 86400);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _seconds,
      builder: (context, sec, _) {
        if (widget.builder != null) return widget.builder!(context, sec);
        return Text(
          formatSeconds(sec),
          style: widget.style,
        );
      },
    );
  }
}
