import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animasyon performansı — UI thread'i kilitlemeden 60–120 FPS hedefi.
abstract final class AnimationPerf {
  /// Parallax scroll güncelleme eşiği (px).
  static const double scrollParallaxThreshold = 0.5;

  /// Yüzen emoji parçacık üst sınırı.
  static const int maxFloatingEmojiParticles = 24;

  /// Canlı etkileşim parçacık üst sınırı.
  static const int maxFxParticles = 48;

  /// Animasyon katmanını izole eder — üst ağaç repaint etmez.
  static Widget isolated(Widget child) => RepaintBoundary(child: child);

  /// [Listenable] ile yalnızca CustomPaint yeniden çizer; build/setState yok.
  static Widget paintLayer({
    required Listenable repaint,
    required CustomPainter painter,
    Size? size,
  }) {
    return isolated(
      RepaintBoundary(
        child: CustomPaint(
          painter: _RepaintListenablePainter(repaint: repaint, delegate: painter),
          size: size ?? Size.infinite,
        ),
      ),
    );
  }
}

/// Scroll parallax — sayfa setState yerine yalnızca dinleyen katman rebuild olur.
class ScrollParallaxNotifier extends ChangeNotifier {
  ScrollParallaxNotifier({this.threshold = AnimationPerf.scrollParallaxThreshold});

  final double threshold;
  double _offset = 0;

  double get offset => _offset;

  void bind(ScrollController controller) {
    controller.addListener(() => update(controller.offset));
  }

  void update(double next) {
    if ((next - _offset).abs() > threshold) {
      _offset = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Tab swipe sırasında her karede değil, yalnızca sekme değişince bildirir.
class TabIndexListenable extends ChangeNotifier {
  TabIndexListenable(TabController controller)
      : _controller = controller,
        _index = controller.index {
    _controller.addListener(_onTick);
  }

  final TabController _controller;
  int _index;

  int get index => _index;
  TabController get controller => _controller;

  void _onTick() {
    final next = _controller.index;
    if (next != _index) {
      _index = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    super.dispose();
  }
}

/// Yüzen emoji parçacıkları — tek CustomPaint, setState yok.
class FloatingEmojiPaintLayer extends StatefulWidget {
  const FloatingEmojiPaintLayer({
    super.key,
    this.emojis = const ['💖', '🌹', '⭐'],
    this.ambientInterval = const Duration(milliseconds: 900),
    this.maxParticles = AnimationPerf.maxFloatingEmojiParticles,
    this.bottomFraction = 0.12,
    this.heightFraction = 0.5,
    this.enabled = true,
  });

  final List<String> emojis;
  final Duration ambientInterval;
  final int maxParticles;
  final double bottomFraction;
  final double heightFraction;
  final bool enabled;

  @override
  State<FloatingEmojiPaintLayer> createState() => FloatingEmojiPaintLayerState();
}

class FloatingEmojiPaintLayerState extends State<FloatingEmojiPaintLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  final _particles = <_FloatEmoji>[];
  final _rand = math.Random();
  Timer? _ambientTimer;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    if (widget.enabled) {
      _scheduleAmbient();
    }
  }

  void _scheduleAmbient() {
    _ambientTimer?.cancel();
    _ambientTimer = Timer(widget.ambientInterval, () {
      if (!mounted || !widget.enabled) return;
      _spawn();
      _scheduleAmbient();
    });
  }

  void burst(String emoji, {int count = 8}) {
    if (!mounted) return;
    for (var i = 0; i < count; i++) {
      _add(_FloatEmoji(
        emoji: emoji,
        xNorm: 0.35 + _rand.nextDouble() * 0.5,
        phase: _rand.nextDouble(),
      ));
    }
  }

  void _spawn({String? emoji}) {
    _add(_FloatEmoji(
      emoji: emoji ?? widget.emojis[_rand.nextInt(widget.emojis.length)],
      xNorm: 0.5 + _rand.nextDouble() * 0.42,
      phase: _rand.nextDouble(),
    ));
  }

  void _add(_FloatEmoji p) {
    _particles.add(p);
    while (_particles.length > widget.maxParticles) {
      _particles.removeAt(0);
    }
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimationPerf.paintLayer(
        repaint: _tick,
        painter: _FloatEmojiPainter(
          particles: _particles,
          tick: _tick,
          bottomFraction: widget.bottomFraction,
          heightFraction: widget.heightFraction,
        ),
      ),
    );
  }
}

class _FloatEmoji {
  _FloatEmoji({required this.emoji, required this.xNorm, required this.phase});

  final String emoji;
  final double xNorm;
  final double phase;
}

class _FloatEmojiPainter extends CustomPainter {
  _FloatEmojiPainter({
    required this.particles,
    required this.tick,
    required this.bottomFraction,
    required this.heightFraction,
  }) : super(repaint: tick);

  final List<_FloatEmoji> particles;
  final Animation<double> tick;
  final double bottomFraction;
  final double heightFraction;

  static final _textCache = <String, TextPainter>{};

  TextPainter _emojiPainter(String emoji, double fontSize, double opacity) {
    final bucket = (opacity * 8).floor().clamp(0, 8);
    final key = '$emoji@${fontSize.toStringAsFixed(0)}@$bucket';
    return _textCache.putIfAbsent(key, () {
      final alpha = bucket / 8;
      final tp = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * bottomFraction;
    final travel = size.height * heightFraction;
    for (final p in particles) {
      final t = (tick.value + p.phase) % 1.0;
      final opacity = (1 - t).clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;
      final fontSize = 18 + t * 16;
      final tp = _emojiPainter(p.emoji, fontSize, opacity);
      tp.paint(canvas, Offset(p.xNorm * size.width, baseY + t * travel));
    }
  }

  @override
  bool shouldRepaint(covariant _FloatEmojiPainter old) => true;
}

/// Önceden hesaplanmış yıldız alanı — paint() içinde Random yok.
class StarPoint {
  const StarPoint({
    required this.x,
    required this.y,
    required this.base,
    required this.radius,
    required this.glow,
  });

  final double x;
  final double y;
  final double base;
  final double radius;
  final bool glow;
}

class PrecomputedStarField {
  PrecomputedStarField._(this.points);

  final List<StarPoint> points;

  factory PrecomputedStarField.generate({
    required Size size,
    required int seed,
    required double density,
  }) {
    final rnd = math.Random(seed);
    final count =
        (size.width * size.height * 0.00035 * density).round().clamp(180, 900);
    final points = <StarPoint>[];
    for (var i = 0; i < count; i++) {
      points.add(StarPoint(
        x: rnd.nextDouble() * size.width,
        y: rnd.nextDouble() * size.height,
        base: rnd.nextDouble(),
        radius: 0.4 + rnd.nextDouble() * 1.6,
        glow: rnd.nextDouble() > 0.88,
      ));
    }
    return PrecomputedStarField._(points);
  }
}

/// Sabit parçacık yörüngeleri — sesli oda arka planı.
class PrecomputedDriftParticles {
  PrecomputedDriftParticles._(this.points);

  final List<_DriftPoint> points;

  factory PrecomputedDriftParticles.generate({
    required int seed,
    required int count,
  }) {
    final rnd = math.Random(seed);
    return PrecomputedDriftParticles._(
      List.generate(count, (_) {
        return _DriftPoint(
          x: rnd.nextDouble(),
          y: rnd.nextDouble() * 0.55,
          alpha: 0.04 + rnd.nextDouble() * 0.08,
          radius: 1.2 + rnd.nextDouble(),
          phase: rnd.nextDouble(),
        );
      }),
    );
  }
}

class _DriftPoint {
  const _DriftPoint({
    required this.x,
    required this.y,
    required this.alpha,
    required this.radius,
    required this.phase,
  });

  final double x;
  final double y;
  final double alpha;
  final double radius;
  final double phase;
}

class _RepaintListenablePainter extends CustomPainter {
  _RepaintListenablePainter({
    required this.repaint,
    required this.delegate,
  }) : super(repaint: repaint);

  final Listenable repaint;
  final CustomPainter delegate;

  @override
  void paint(Canvas canvas, Size size) => delegate.paint(canvas, size);

  @override
  bool shouldRepaint(covariant _RepaintListenablePainter old) =>
      delegate.shouldRepaint(old.delegate);

  @override
  bool? hitTest(Offset position) => delegate.hitTest(position);

  @override
  SemanticsBuilderCallback? get semanticsBuilder => delegate.semanticsBuilder;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) =>
      delegate.shouldRebuildSemantics(oldDelegate);
}

/// İlk karede animasyonu erteler — scroll/liste açılışında jank azaltır.
class DeferredTickerMode extends StatefulWidget {
  const DeferredTickerMode({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 120),
  });

  final Widget child;
  final Duration delay;

  @override
  State<DeferredTickerMode> createState() => _DeferredTickerModeState();
}

class _DeferredTickerModeState extends State<DeferredTickerMode> {
  var _enabled = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _enabled = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(enabled: _enabled, child: widget.child);
  }
}
