import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import 'canlifal_motion_tokens.dart';

/// Tarot kartı — Y ekseni flip (seçim / açılış).
///
/// Çevrilirken kart masadan hafifçe kalkar (ölçek + büyüyen gölge) ve yüzeyinden
/// bir ışık yansıması geçer; "animasyonları azalt" açıksa anında çevrilir.
class CanlifalTarotFlipCard extends StatefulWidget {
  const CanlifalTarotFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.flipped = false,
    this.onFlipComplete,
    this.width = 96,
    this.height = 142,
    this.borderRadius = 12,
  });

  final Widget front;
  final Widget back;
  final bool flipped;
  final VoidCallback? onFlipComplete;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<CanlifalTarotFlipCard> createState() => _CanlifalTarotFlipCardState();
}

class _CanlifalTarotFlipCardState extends State<CanlifalTarotFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 720),
        value: widget.flipped ? 1 : 0,
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onFlipComplete?.call();
      });

  late final Animation<double> _turn = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOutCubic,
    reverseCurve: CanlifalMotionTokens.easeIn,
  );

  @override
  void didUpdateWidget(covariant CanlifalTarotFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipped == oldWidget.flipped) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // value=1 durum dinleyicisini tetikler; onFlipComplete orada çağrılır.
      _c.value = widget.flipped ? 1 : 0;
      return;
    }
    widget.flipped ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _turn,
        builder: (_, _) {
          final t = _turn.value;
          final angle = t * pi;
          // Dönüşün ortasında en yüksek: kart kalkar, gölge büyür, ışık geçer.
          final lift = sin(t * pi);
          final isUnder = angle >= pi / 2;

          final face = isUnder
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: widget.back,
                )
              : widget.front;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..scaleByDouble(1 + 0.08 * lift, 1 + 0.08 * lift, 1, 1)
              ..rotateY(angle),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25 + 0.25 * lift),
                    blurRadius: 8 + 22 * lift,
                    offset: Offset(0, 4 + 10 * lift),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      face,
                      if (lift > 0.02)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.6 + 3.2 * t, -1),
                                end: Alignment(-0.6 + 3.2 * t, 1),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.28 * lift),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
