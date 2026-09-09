import 'package:flutter/material.dart';

/// Oda sohbeti «yazıyor» göstergesi — animasyonlu noktalar.
class VoiceRoomTypingIndicator extends StatefulWidget {
  const VoiceRoomTypingIndicator({
    super.key,
    required this.userNames,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 4),
  });

  final List<String> userNames;
  final EdgeInsetsGeometry padding;

  @override
  State<VoiceRoomTypingIndicator> createState() =>
      _VoiceRoomTypingIndicatorState();
}

class _VoiceRoomTypingIndicatorState extends State<VoiceRoomTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  String _label() {
    final names = widget.userNames.where((n) => n.trim().isNotEmpty).toList();
    if (names.isEmpty) return 'Birisi yazıyor';
    if (names.length == 1) return '${names.first} yazıyor';
    if (names.length == 2) return '${names[0]} ve ${names[1]} yazıyor';
    return '${names[0]} ve ${names.length - 1} kişi yazıyor';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          _AnimatedDots(animation: _dots),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _label(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (animation.value + i * 0.2) % 1.0;
            final scale = 0.55 + (phase < 0.5 ? phase : 1 - phase) * 0.9;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB832FF).withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
