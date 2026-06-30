import 'dart:math';

import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TikTok tarzı etkileşim — emoji yağmuru, süper beğeni, alkış.
/// Parçacık fizikleri paint katmanında; setState yok.
class LiveInteractionEffectsOverlay extends StatefulWidget {
  const LiveInteractionEffectsOverlay({
    super.key,
    this.burstToken = 0,
    this.superLikeToken = 0,
    this.emojiRainToken = 0,
    this.applauseToken = 0,
  });

  final int burstToken;
  final int superLikeToken;
  final int emojiRainToken;
  final int applauseToken;

  @override
  State<LiveInteractionEffectsOverlay> createState() =>
      _LiveInteractionEffectsOverlayState();
}

class _LiveInteractionEffectsOverlayState extends State<LiveInteractionEffectsOverlay>
    with SingleTickerProviderStateMixin {
  final _particles = <_FxParticle>[];
  late AnimationController _tick;
  final _rng = Random();
  Size _lastSize = Size.zero;

  static const _emojis = ['❤️', '💖', '✨', '⭐', '🔥', '👏', '🌟', '💫'];

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _tick.addListener(_step);
  }

  @override
  void didUpdateWidget(covariant LiveInteractionEffectsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstToken != oldWidget.burstToken) _spawnHearts(6);
    if (widget.superLikeToken != oldWidget.superLikeToken) {
      _spawnHearts(16);
      HapticFeedback.heavyImpact();
    }
    if (widget.emojiRainToken != oldWidget.emojiRainToken) _spawnRain(24);
    if (widget.applauseToken != oldWidget.applauseToken) {
      _spawnRain(12, emoji: '👏');
    }
  }

  void _spawnHearts(int count) {
    if (_lastSize == Size.zero) return;
    for (var i = 0; i < count; i++) {
      if (_particles.length >= AnimationPerf.maxFxParticles) break;
      _particles.add(_FxParticle(
        emoji: '❤️',
        x: _rng.nextDouble() * _lastSize.width,
        y: _lastSize.height * 0.75,
        vy: -2.5 - _rng.nextDouble() * 3,
        life: 1.0,
      ));
    }
  }

  void _spawnRain(int count, {String? emoji}) {
    if (_lastSize == Size.zero) return;
    for (var i = 0; i < count; i++) {
      if (_particles.length >= AnimationPerf.maxFxParticles) break;
      _particles.add(_FxParticle(
        emoji: emoji ?? _emojis[_rng.nextInt(_emojis.length)],
        x: _rng.nextDouble() * _lastSize.width,
        y: -20 - _rng.nextDouble() * 80,
        vy: 2 + _rng.nextDouble() * 4,
        life: 1.0,
      ));
    }
  }

  void _step() {
    if (_particles.isEmpty) return;
    for (final p in _particles) {
      p.y += p.vy;
      p.life -= 0.018;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void dispose() {
    _tick
      ..removeListener(_step)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _lastSize = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimationPerf.paintLayer(
        repaint: _tick,
        painter: _FxPainter(_particles),
      ),
    );
  }
}

class _FxParticle {
  _FxParticle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.vy,
    required this.life,
  });

  String emoji;
  double x;
  double y;
  double vy;
  double life;
}

class _FxPainter extends CustomPainter with PaintLayerDelegate {
  _FxPainter(this.particles);

  final List<_FxParticle> particles;

  static const _maxTextCacheEntries = 48;
  static final _textCache = <String, TextPainter>{};

  TextPainter _emoji(String emoji, double fontSize) {
    final key = '$emoji@${fontSize.toStringAsFixed(0)}';
    if (_textCache.length > _maxTextCacheEntries) {
      _textCache.clear();
    }
    return _textCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final fontSize = 18 + p.life * 8;
      _emoji(p.emoji, fontSize).paint(canvas, Offset(p.x, p.y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
