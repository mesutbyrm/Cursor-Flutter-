import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';


/// Çift dokunuş kalpleri — yalnızca gerçek beğeni dokunuşunda animasyon.
class LiveFloatingHeartsOverlay extends StatefulWidget {
  const LiveFloatingHeartsOverlay({
    super.key,
    required this.burstToken,
    this.enabled = true,
    this.onDoubleTap,
    this.onTripleTap,
    this.onLongPress,
    this.pkRailMode = false,
  });

  final int burstToken;
  final bool enabled;
  final bool pkRailMode;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTripleTap;
  final VoidCallback? onLongPress;

  @override
  State<LiveFloatingHeartsOverlay> createState() =>
      LiveFloatingHeartsOverlayState();
}

class LiveFloatingHeartsOverlayState extends State<LiveFloatingHeartsOverlay>
    with SingleTickerProviderStateMixin {
  static const _maxHearts = 30;
  static const _colors = [
    Color(0xFFFF2D7A),
    Color(0xFFFF6B9D),
    Color(0xFFFF3B3B),
    Color(0xFFB832FF),
    Colors.white,
  ];

  late final Ticker _ticker;
  final _hearts = <_HeartParticle>[];
  final _rand = Random();
  Duration _now = Duration.zero;
  Offset? _lastTap;

  @override
  void initState() {
    super.initState();
    // Ticker yalnız ekranda kalp varken çalışır — boşta kare üretmez.
    _ticker = createTicker((elapsed) {
      _now = elapsed;
      _hearts.removeWhere((h) => (_now - h.born) >= h.life);
      if (_hearts.isEmpty) _ticker.stop();
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant LiveFloatingHeartsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstToken != oldWidget.burstToken) {
      final delta = (widget.burstToken - oldWidget.burstToken).clamp(1, 5);
      _spawn(count: delta, fromTap: _lastTap);
    }
  }

  void burstAt(Offset globalPos, {int count = 12}) {
    _lastTap = globalPos;
    _spawn(count: count, fromTap: globalPos);
  }

  void _spawn({required int count, Offset? fromTap}) {
    if (!mounted) return;
    final rail = widget.pkRailMode;
    final w = MediaQuery.sizeOf(context).width;
    if (!_ticker.isActive) {
      _ticker.start();
      _now = Duration.zero;
    }
    for (var i = 0; i < count; i++) {
      _hearts.add(
        _HeartParticle(
          born: _now + Duration(milliseconds: i * 60),
          life: Duration(milliseconds: 2200 + _rand.nextInt(1100)),
          left: fromTap != null
              ? (fromTap.dx / w).clamp(rail ? 0.68 : 0.2, rail ? 0.92 : 0.85)
              : (rail ? 0.74 : 0.80) + _rand.nextDouble() * 0.12,
          phase: _rand.nextDouble() * pi * 2,
          sway: 14 + _rand.nextDouble() * 26,
          size: 16 + _rand.nextDouble() * 22,
          tilt: (_rand.nextDouble() - 0.5) * 0.7,
          color: _colors[_rand.nextInt(_colors.length)],
        ),
      );
    }
    if (_hearts.length > _maxHearts) {
      _hearts.removeRange(0, _hearts.length - _maxHearts);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _registerTap(Offset? globalPos) {
    if (globalPos != null) _lastTap = globalPos;
    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;
    final rise = widget.pkRailMode ? h * 0.48 : h * 0.55;
    final baseBottom = widget.pkRailMode ? h * 0.22 : h * 0.18;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () => _registerTap(_lastTap),
      onLongPress: widget.onLongPress,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (d) => _lastTap = d.position,
        child: IgnorePointer(
          child: RepaintBoundary(
            child: Stack(
              children: [
                for (final p in _hearts)
                  if (_now >= p.born)
                    _buildHeart(p, w, baseBottom, rise),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeart(_HeartParticle p, double w, double baseBottom, double rise) {
    final t = ((_now - p.born).inMicroseconds / p.life.inMicroseconds)
        .clamp(0.0, 1.0);
    // Yukarı: başta hızlı, sonda yavaşlar. Yatay: sinüs salınımı.
    final y = Curves.easeOutCubic.transform(t) * rise;
    final x = w * p.left + sin(t * pi * 2.2 + p.phase) * p.sway;
    // Giriş: 0→15% arası pop (0.3→1); son %35'te solma.
    final pop = t < 0.15 ? Curves.easeOutBack.transform(t / 0.15) : 1.0;
    final scale = 0.3 + 0.7 * pop;
    final opacity = t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
    return Positioned(
      left: x,
      bottom: baseBottom + y,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: p.tilt,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.favorite_rounded,
              color: p.color,
              size: p.size,
              shadows: [
                Shadow(color: p.color.withValues(alpha: 0.7), blurRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartParticle {
  _HeartParticle({
    required this.born,
    required this.life,
    required this.left,
    required this.phase,
    required this.sway,
    required this.size,
    required this.tilt,
    required this.color,
  });

  final Duration born;
  final Duration life;
  final double left;
  final double phase;
  final double sway;
  final double size;
  final double tilt;
  final Color color;
}
