import 'package:flutter/material.dart';

import '../../../../../core/ui/premium_2026/premium_motion.dart';

/// Splash / auth — neon halka yükleme göstergesi.
class AuthPremiumLoading extends StatefulWidget {
  const AuthPremiumLoading({super.key, this.size = 44});

  final double size;

  @override
  State<AuthPremiumLoading> createState() => _AuthPremiumLoadingState();
}

class _AuthPremiumLoadingState extends State<AuthPremiumLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, child) {
          return Transform.rotate(
            angle: _spin.value * 6.28318,
            child: child,
          );
        },
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _RingPainter(),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const colors = [
      Color(0xFFFF2D7A),
      Color(0xFF9B4DFF),
      Color(0xFF00D2FF),
      Color(0xFFFF2D7A),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        startAngle: 0,
        endAngle: 6.28,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.2,
      4.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Alt çubuk — yumuşak ilerleme hissi.
class AuthPremiumLoadingBar extends StatefulWidget {
  const AuthPremiumLoadingBar({super.key});

  @override
  State<AuthPremiumLoadingBar> createState() => _AuthPremiumLoadingBarState();
}

class _AuthPremiumLoadingBarState extends State<AuthPremiumLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final barW = (w * 0.42).clamp(140.0, 220.0);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: barW,
            height: 4,
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.35 + _pulse.value * 0.45,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF9B4DFF),
                          Color(0xFFFF2D7A),
                          Color(0xFF00D2FF),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
