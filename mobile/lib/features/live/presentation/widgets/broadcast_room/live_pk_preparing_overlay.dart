import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Kabul sonrası kısa 3-2-1 hazırlık — video paneller görünür kalır.
class LivePkPreparingOverlay extends StatefulWidget {
  const LivePkPreparingOverlay({
    super.key,
    required this.visible,
    this.leftName = 'Host A',
    this.rightName = 'Host B',
    this.onFinished,
  });

  final bool visible;
  final String leftName;
  final String rightName;
  final VoidCallback? onFinished;

  @override
  State<LivePkPreparingOverlay> createState() => _LivePkPreparingOverlayState();
}

class _LivePkPreparingOverlayState extends State<LivePkPreparingOverlay> {
  var _step = 3;
  Timer? _timer;
  var _running = false;

  @override
  void didUpdateWidget(covariant LivePkPreparingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_running) {
      _start();
    }
    if (!widget.visible && _running) {
      _stop();
    }
  }

  void _start() {
    _stop();
    _running = true;
    _step = 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_step <= 1) {
        _stop();
        widget.onFinished?.call();
        return;
      }
      setState(() => _step -= 1);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || !_running) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PK',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _nameChip(widget.leftName, const Color(0xFFFF2D7A)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
                _nameChip(widget.rightName, const Color(0xFF448AFF)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Hazırlanıyor...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$_step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            )
                .animate(key: ValueKey(_step))
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 320.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 180.ms),
          ],
        ),
      ),
    );
  }

  Widget _nameChip(String name, Color accent) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
