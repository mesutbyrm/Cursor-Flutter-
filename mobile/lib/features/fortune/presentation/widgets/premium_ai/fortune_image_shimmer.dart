import 'package:flutter/material.dart';

/// Yükleme sırasında premium shimmer efekti.
class FortuneImageShimmer extends StatefulWidget {
  const FortuneImageShimmer({
    super.key,
    required this.accent,
    this.emoji,
  });

  final Color accent;
  final String? emoji;

  @override
  State<FortuneImageShimmer> createState() => _FortuneImageShimmerState();
}

class _FortuneImageShimmerState extends State<FortuneImageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + _ctrl.value * 2, 0),
              end: Alignment(_ctrl.value * 2, 0),
              colors: [
                widget.accent.withValues(alpha: 0.12),
                widget.accent.withValues(alpha: 0.35),
                widget.accent.withValues(alpha: 0.12),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: widget.emoji != null
              ? Text(widget.emoji!, style: const TextStyle(fontSize: 40))
              : Icon(Icons.auto_awesome, color: widget.accent.withValues(alpha: 0.7), size: 36),
        );
      },
    );
  }
}
