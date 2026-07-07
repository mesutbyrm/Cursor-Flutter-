import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/performance/animation_perf.dart';
import 'voice_rooms_ui_tokens.dart';

/// Sesli Odalar — ses dalgası, neon, partikül, Lottie efektleri.
abstract final class VoiceRoomsFx {
  static const lottieStar = 'assets/gifts/lottie/star.json';
  static const lottieHeart = 'assets/gifts/lottie/heart.json';

  static Widget sectionEnter(Widget child, {int delayMs = 0}) {
    return child
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.035, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}

/// Eşit ses dalgası çubukları — AppBar, kategori, canlı rozet.
class VoiceSoundWaveBars extends StatefulWidget {
  const VoiceSoundWaveBars({
    super.key,
    this.size = 20,
    this.color = VoiceRoomsUiTokens.purpleGlow,
    this.barCount = 4,
    this.active = true,
  });

  final double size;
  final Color color;
  final int barCount;
  final bool active;

  @override
  State<VoiceSoundWaveBars> createState() => _VoiceSoundWaveBarsState();
}

class _VoiceSoundWaveBarsState extends State<VoiceSoundWaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant VoiceSoundWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return VoiceRoomsSvgBars.static(
        size: widget.size,
        color: widget.color.withValues(alpha: 0.35),
        barCount: widget.barCount,
      );
    }
    return AnimationPerf.isolated(
      AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return VoiceRoomsSvgBars.animated(
            t: _ctrl.value,
            size: widget.size,
            color: widget.color,
            barCount: widget.barCount,
          );
        },
      ),
    );
  }
}

/// Inline ses çubukları — SVG asset gerekmez.
abstract final class VoiceRoomsSvgBars {
  static Widget static({
    required double size,
    required Color color,
    required int barCount,
  }) {
    return _BarsLayout(
      heights: List.filled(barCount, 0.45),
      size: size,
      color: color,
      barCount: barCount,
    );
  }

  static Widget animated({
    required double t,
    required double size,
    required Color color,
    required int barCount,
  }) {
    final heights = List<double>.generate(barCount, (i) {
      final phase = t * math.pi * 2 + i * 0.9;
      return 0.28 + 0.72 * ((math.sin(phase) + 1) / 2);
    });
    return _BarsLayout(
      heights: heights,
      size: size,
      color: color,
      barCount: barCount,
    );
  }
}

class _BarsLayout extends StatelessWidget {
  const _BarsLayout({
    required this.heights,
    required this.size,
    required this.color,
    required this.barCount,
  });

  final List<double> heights;
  final double size;
  final Color color;
  final int barCount;

  @override
  Widget build(BuildContext context) {
    final barW = size * 0.18;
    final gap = size * 0.08;
    return SizedBox(
      width: barCount * barW + (barCount - 1) * gap,
      height: size,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (i) {
          final h = size * heights[i.clamp(0, heights.length - 1)];
          return Padding(
            padding: EdgeInsets.only(right: i == barCount - 1 ? 0 : gap),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: barW,
              height: h.clamp(size * 0.2, size),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(barW),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Mikrofon ses seviyesi — 5 çubuk, bağımsız faz.
class VoiceMicLevelBars extends StatefulWidget {
  const VoiceMicLevelBars({
    super.key,
    this.width = 28,
    this.height = 14,
    this.color = VoiceRoomsUiTokens.onlineGreen,
    this.active = true,
  });

  final double width;
  final double height;
  final Color color;
  final bool active;

  @override
  State<VoiceMicLevelBars> createState() => _VoiceMicLevelBarsState();
}

class _VoiceMicLevelBarsState extends State<VoiceMicLevelBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant VoiceMicLevelBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) _ctrl.repeat();
    if (!widget.active) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationPerf.isolated(
      SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final t = _ctrl.value;
                final phase = t * math.pi * 2 + i * 1.1;
                final level = widget.active
                    ? 0.25 + 0.75 * ((math.sin(phase) + 1) / 2)
                    : 0.2;
                return Container(
                  width: widget.width * 0.12,
                  height: widget.height * level,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

/// Canlı konuşmacı avatarı — nabız glow halkası.
class VoiceLiveAvatarGlow extends StatefulWidget {
  const VoiceLiveAvatarGlow({
    super.key,
    required this.child,
    this.glowColor = VoiceRoomsUiTokens.onlineGreen,
    this.live = true,
    this.size = 56,
  });

  final Widget child;
  final Color glowColor;
  final bool live;
  final double size;

  @override
  State<VoiceLiveAvatarGlow> createState() => _VoiceLiveAvatarGlowState();
}

class _VoiceLiveAvatarGlowState extends State<VoiceLiveAvatarGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.live) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant VoiceLiveAvatarGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.live && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.live) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationPerf.isolated(
      AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final expand = 1.0 + _pulse.value * 0.14;
          final alpha = widget.live ? 0.22 + _pulse.value * 0.38 : 0.0;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.live)
                Container(
                  width: widget.size * expand,
                  height: widget.size * expand,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: alpha),
                        blurRadius: 18 + _pulse.value * 10,
                        spreadRadius: 2 + _pulse.value * 4,
                      ),
                    ],
                  ),
                ),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Oda arka planı — yavaş hareketli partiküller.
class VoiceRoomParticleField extends StatefulWidget {
  const VoiceRoomParticleField({super.key, this.particleCount = 14});

  final int particleCount;

  @override
  State<VoiceRoomParticleField> createState() => _VoiceRoomParticleFieldState();
}

class _VoiceRoomParticleFieldState extends State<VoiceRoomParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  late final List<_Particle> _particles;
  final _rand = math.Random(42);

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        radius: 1.2 + _rand.nextDouble() * 2.8,
        speed: 0.15 + _rand.nextDouble() * 0.35,
        phase: _rand.nextDouble() * math.pi * 2,
        color: [
          VoiceRoomsUiTokens.purpleGlow,
          VoiceRoomsUiTokens.magenta,
          VoiceRoomsUiTokens.blue,
        ][_rand.nextInt(3)],
      );
    });
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimationPerf.isolated(
        CustomPaint(
          painter: _ParticlePainter(particles: _particles, tick: _tick),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.tick})
      : super(repaint: tick);

  final List<_Particle> particles;
  final Animation<double> tick;

  @override
  void paint(Canvas canvas, Size size) {
    final t = tick.value;
    for (final p in particles) {
      final dx = math.sin(t * math.pi * 2 * p.speed + p.phase) * 12;
      final dy = math.cos(t * math.pi * 2 * p.speed * 0.7 + p.phase) * 16;
      final px = p.x * size.width + dx;
      final py = p.y * size.height + dy;
      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.18 + 0.12 * math.sin(t * 6 + p.phase))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Dinamik gradient arka plan — yavaş renk kayması.
class VoiceDynamicGradientBackground extends StatefulWidget {
  const VoiceDynamicGradientBackground({super.key});

  @override
  State<VoiceDynamicGradientBackground> createState() =>
      _VoiceDynamicGradientBackgroundState();
}

class _VoiceDynamicGradientBackgroundState extends State<VoiceDynamicGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationPerf.isolated(
      AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: VoiceRoomsUiTokens.bgAmoled),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + t * 0.4, -0.8),
                    end: Alignment(1 - t * 0.3, 1),
                    colors: [
                      VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.14 + t * 0.06),
                      Colors.transparent,
                      VoiceRoomsUiTokens.magenta.withValues(alpha: 0.08),
                      VoiceRoomsUiTokens.blue.withValues(alpha: 0.06 + (1 - t) * 0.05),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: -100,
                right: -60,
                child: _glowOrb(
                  VoiceRoomsUiTokens.purpleGlow,
                  240,
                  0.22 + math.sin(t * math.pi * 2) * 0.04,
                ),
              ),
              Positioned(
                top: 280,
                left: -80,
                child: _glowOrb(
                  VoiceRoomsUiTokens.magenta,
                  200,
                  0.12 + math.cos(t * math.pi * 2) * 0.03,
                ),
              ),
              Positioned(
                bottom: 120,
                right: -40,
                child: _glowOrb(
                  VoiceRoomsUiTokens.blue,
                  160,
                  0.10,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _glowOrb(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.12,
          ),
        ],
      ),
    );
  }
}

/// 3D neon kart — hafif perspektif + parlayan kenar.
class VoiceNeonCard extends StatefulWidget {
  const VoiceNeonCard({
    super.key,
    required this.child,
    this.glowColor = VoiceRoomsUiTokens.purpleGlow,
    this.radius = VoiceRoomsUiTokens.radiusLg,
    this.enabled = true,
  });

  final Widget child;
  final Color glowColor;
  final double radius;
  final bool enabled;

  @override
  State<VoiceNeonCard> createState() => _VoiceNeonCardState();
}

class _VoiceNeonCardState extends State<VoiceNeonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.enabled) _shimmer.repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationPerf.isolated(
      AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          final angle = _shimmer.value * math.pi * 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(0.02 * math.sin(angle))
              ..rotateY(0.025 * math.cos(angle)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: widget.glowColor.withValues(
                      alpha: 0.12 + 0.08 * math.sin(angle),
                    ),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Küçük Lottie vurgu — mikrofon / yıldız parıltısı.
class VoiceLottieAccent extends StatelessWidget {
  const VoiceLottieAccent({
    super.key,
    this.asset = VoiceRoomsFx.lottieStar,
    this.size = 22,
    this.repeat = true,
  });

  final String asset;
  final double size;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          asset,
          fit: BoxFit.contain,
          repeat: repeat,
          frameRate: FrameRate.max,
        ),
      ),
    );
  }
}

/// Premium kategori / mikrofon ikon kabı — neon + dalga + Lottie.
class VoicePremiumCategoryIcon extends StatelessWidget {
  const VoicePremiumCategoryIcon({
    super.key,
    required this.iconKey,
    required this.colors,
    required this.active,
    this.showLottie = false,
  });

  final String iconKey;
  final List<Color> colors;
  final bool active;
  final bool showLottie;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForKey(iconKey, active: active, colors: colors);
    if (!active) return icon;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        icon,
        if (showLottie)
          const Positioned(
            top: -4,
            right: -4,
            child: VoiceLottieAccent(size: 16),
          ),
        Positioned(
          bottom: -2,
          child: VoiceSoundWaveBars(
            size: 12,
            color: colors.first,
            barCount: 3,
            active: active,
          ),
        ),
      ],
    );
  }

  Widget _iconForKey(String key, {required bool active, required List<Color> colors}) {
    // Premium SVG paths inlined — glow layer when active.
    return CustomPaint(
      size: const Size(24, 24),
      painter: _PremiumIconPainter(
        iconKey: key,
        color: active ? Colors.white : colors.first,
        glow: active,
        glowColor: colors.first,
      ),
    );
  }
}

class _PremiumIconPainter extends CustomPainter {
  _PremiumIconPainter({
    required this.iconKey,
    required this.color,
    required this.glow,
    required this.glowColor,
  });

  final String iconKey;
  final Color color;
  final bool glow;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (glow) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.42, glowPaint);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()..color = color;

    if (iconKey == 'music') {
      canvas.drawLine(Offset(size.width * 0.35, size.height * 0.75), Offset(size.width * 0.35, size.height * 0.25), paint);
      canvas.drawLine(Offset(size.width * 0.35, size.height * 0.25), Offset(size.width * 0.82, size.height * 0.18), paint);
      canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.78), size.width * 0.12, paint);
      canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.72), size.width * 0.12, paint);
    } else if (iconKey == 'fire') {
      final path = Path()
        ..moveTo(size.width * 0.5, size.height * 0.92)
        ..cubicTo(size.width * 0.15, size.height * 0.55, size.width * 0.35, size.height * 0.2, size.width * 0.5, size.height * 0.12)
        ..cubicTo(size.width * 0.62, size.height * 0.28, size.width * 0.78, size.height * 0.42, size.width * 0.5, size.height * 0.92);
      canvas.drawPath(path, fill);
    } else {
      _paintMic(canvas, size, paint);
    }
  }

  void _paintMic(Canvas canvas, Size size, Paint paint) {
    final body = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.42),
            width: size.width * 0.34,
            height: size.height * 0.48,
          ),
          Radius.circular(size.width * 0.17),
        );
        canvas.drawRRect(body, paint);
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.58),
            width: size.width * 0.55,
            height: size.height * 0.38,
          ),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.5, size.height * 0.72),
          Offset(size.width * 0.5, size.height * 0.88),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.35, size.height * 0.88),
          Offset(size.width * 0.65, size.height * 0.88),
          paint,
        );
  }

  @override
  bool shouldRepaint(covariant _PremiumIconPainter oldDelegate) =>
      oldDelegate.iconKey != iconKey ||
      oldDelegate.color != color ||
      oldDelegate.glow != glow;
}

/// Gelişmiş cam kart — blur + animasyonlu kenar parıltısı.
class VoiceGlassFxContainer extends StatefulWidget {
  const VoiceGlassFxContainer({
    super.key,
    required this.child,
    this.radius = VoiceRoomsUiTokens.radiusLg,
    this.padding,
    this.glowColor,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;

  @override
  State<VoiceGlassFxContainer> createState() => _VoiceGlassFxContainerState();
}

class _VoiceGlassFxContainerState extends State<VoiceGlassFxContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _edge;

  @override
  void initState() {
    super.initState();
    _edge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _edge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? VoiceRoomsUiTokens.purpleGlow;
    return AnimationPerf.isolated(
      AnimatedBuilder(
        animation: _edge,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glow.withValues(alpha: 0.35 + 0.15 * math.sin(_edge.value * math.pi * 2)),
                  Colors.white.withValues(alpha: 0.08),
                  glow.withValues(alpha: 0.2 + 0.1 * math.cos(_edge.value * math.pi * 2)),
                ],
              ),
              boxShadow: VoiceRoomsUiTokens.glowShadow(glow, blur: 16),
            ),
            padding: const EdgeInsets.all(1.2),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius - 1),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(VoiceRoomsUiTokens.gapMd),
              decoration: VoiceRoomsUiTokens.glass(radius: widget.radius - 1),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
