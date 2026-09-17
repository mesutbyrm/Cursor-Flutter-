import 'dart:math' show pi;

import 'package:flutter/material.dart';

import 'canlifal_motion_tokens.dart';

/// Tarot kartı — Y ekseni flip (seçim / açılış).
class CanlifalTarotFlipCard extends StatefulWidget {
  const CanlifalTarotFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.flipped = false,
    this.onFlipComplete,
    this.width = 96,
    this.height = 142,
  });

  final Widget front;
  final Widget back;
  final bool flipped;
  final VoidCallback? onFlipComplete;
  final double width;
  final double height;

  @override
  State<CanlifalTarotFlipCard> createState() => _CanlifalTarotFlipCardState();
}

class _CanlifalTarotFlipCardState extends State<CanlifalTarotFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _turn;
  var _showFront = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: CanlifalMotionTokens.premium,
    );
    _turn = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _c, curve: CanlifalMotionTokens.easeOut),
    );
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onFlipComplete?.call();
      }
    });
    if (widget.flipped) {
      _showFront = false;
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant CanlifalTarotFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipped != oldWidget.flipped) {
      if (widget.flipped) {
        _c.forward();
        _showFront = false;
      } else {
        _c.reverse();
        _showFront = true;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _turn,
      builder: (_, child) {
        final angle = _turn.value;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        final isUnder = angle >= pi / 2;
        final face = SizedBox(
          width: widget.width,
          height: widget.height,
          child: isUnder
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: widget.back,
                )
              : widget.front,
        );
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: face,
        );
      },
      child: SizedBox(width: widget.width, height: widget.height),
    );
  }
}
