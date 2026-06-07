import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';


/// Çift dokunuş kalpleri + sürekli yüzen tepkiler.
class LiveFloatingHeartsOverlay extends StatefulWidget {
  const LiveFloatingHeartsOverlay({
    super.key,
    required this.burstToken,
    this.enabled = true,
    this.onDoubleTap,
  });

  final int burstToken;
  final bool enabled;
  final VoidCallback? onDoubleTap;

  @override
  State<LiveFloatingHeartsOverlay> createState() =>
      LiveFloatingHeartsOverlayState();
}

class LiveFloatingHeartsOverlayState extends State<LiveFloatingHeartsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _hearts = <_HeartParticle>[];
  final _rand = Random();
  Timer? _ambient;
  Offset? _lastTap;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _ambient = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!widget.enabled || !mounted) return;
      _spawn(count: 1);
    });
  }

  @override
  void didUpdateWidget(covariant LiveFloatingHeartsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstToken != oldWidget.burstToken) {
      _spawn(count: 10, fromTap: _lastTap);
    }
  }

  void burstAt(Offset globalPos, {int count = 12}) {
    _lastTap = globalPos;
    _spawn(count: count, fromTap: globalPos);
  }

  void _spawn({required int count, Offset? fromTap}) {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < count; i++) {
        final colors = [
          AppThemeColors.accentPink,
          const Color(0xFFFF6B9D),
          AppThemeColors.liveRed,
          Colors.white,
        ];
        _hearts.add(_HeartParticle(
          id: _rand.nextInt(1 << 30),
          left: fromTap != null
              ? (fromTap.dx / MediaQuery.sizeOf(context).width).clamp(0.2, 0.8)
              : 0.55 + _rand.nextDouble() * 0.38,
          phase: _rand.nextDouble(),
          size: 14 + _rand.nextDouble() * 18,
          color: colors[_rand.nextInt(colors.length)],
          drift: _rand.nextDouble() * 0.12 - 0.06,
        ));
      }
      if (_hearts.length > 24) {
        _hearts.removeRange(0, _hearts.length - 24);
      }
    });
  }

  @override
  void dispose() {
    _ambient?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTapDown: (d) {
        _lastTap = d.globalPosition;
        widget.onDoubleTap?.call();
        burstAt(d.globalPosition);
      },
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Stack(
              children: [
                for (final p in _hearts)
                  Positioned(
                    left: w * p.left + sin((_ctrl.value + p.phase) * pi * 2) * 24,
                    bottom: h * 0.18 + ((_ctrl.value + p.phase) % 1.0) * h * 0.55,
                    child: Opacity(
                      opacity: (1 - ((_ctrl.value + p.phase) % 1.0)).clamp(0.0, 1.0),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: p.color,
                        size: p.size,
                        shadows: [
                          Shadow(
                            color: p.color.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeartParticle {
  _HeartParticle({
    required this.id,
    required this.left,
    required this.phase,
    required this.size,
    required this.color,
    required this.drift,
  });

  final int id;
  final double left;
  final double phase;
  final double size;
  final Color color;
  final double drift;
}
