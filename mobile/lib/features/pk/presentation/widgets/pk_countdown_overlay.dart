import 'dart:async';

import 'package:flutter/material.dart';

/// `starting` durumu — 5-4-3-2-1 tam ekran geri sayım.
class PkCountdownOverlay extends StatefulWidget {
  const PkCountdownOverlay({
    super.key,
    required this.seconds,
    this.onFinished,
  });

  final int seconds;
  final VoidCallback? onFinished;

  @override
  State<PkCountdownOverlay> createState() => _PkCountdownOverlayState();
}

class _PkCountdownOverlayState extends State<PkCountdownOverlay> {
  late int _left;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _left = widget.seconds.clamp(1, 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left <= 1) {
        _timer?.cancel();
        widget.onFinished?.call();
        Navigator.of(context).maybePop();
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Text(
          '$_left',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 96,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Future<void> showPkCountdownOverlay(
  BuildContext context, {
  int seconds = 5,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PkCountdownOverlay(seconds: seconds),
  );
}
