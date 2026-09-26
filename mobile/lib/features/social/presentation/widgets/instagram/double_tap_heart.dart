import 'package:flutter/material.dart';

/// Çift dokunuşta büyüyüp sönen kalp. [token] her arttığında bir kez oynar;
/// boşta ticker çalışmaz.
class DoubleTapHeart extends StatefulWidget {
  const DoubleTapHeart({super.key, required this.token, this.size = 96});

  final int token;
  final double size;

  @override
  State<DoubleTapHeart> createState() => _DoubleTapHeartState();
}

class _DoubleTapHeartState extends State<DoubleTapHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.2,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 35,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.6,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 20,
    ),
  ]).animate(_c);

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
  ]).animate(_c);

  @override
  void didUpdateWidget(covariant DoubleTapHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token) {
      if (MediaQuery.disableAnimationsOf(context)) return;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          if (_c.isDismissed || _c.isCompleted) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: _opacity.value,
            child: Transform.scale(scale: _scale.value, child: child),
          );
        },
        child: Icon(
          Icons.favorite_rounded,
          size: widget.size,
          color: Colors.white,
          shadows: const [Shadow(color: Color(0x66000000), blurRadius: 18)],
        ),
      ),
    );
  }
}
