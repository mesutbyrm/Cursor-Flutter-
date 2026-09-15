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

class _PkCountdownOverlayState extends State<PkCountdownOverlay>
    with SingleTickerProviderStateMixin {
  late int _left;
  Timer? _timer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _left <= 3;
    final gold = urgent ? const Color(0xFFFF3B30) : const Color(0xFFFFD700);
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final scale = urgent ? 1.0 + 0.18 * _pulse.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Text(
            '$_left',
            style: TextStyle(
              color: gold,
              fontSize: urgent ? 108 : 96,
              fontWeight: FontWeight.w900,
              shadows: urgent
                  ? [
                      Shadow(
                        color: gold.withValues(alpha: 0.6 * _pulse.value),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
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
