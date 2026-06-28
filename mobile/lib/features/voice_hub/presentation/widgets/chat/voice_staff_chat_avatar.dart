import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/auth/voice_staff_rank.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../utils/voice_staff_chat_style.dart';
import '../../theme/voice_room_tokens.dart';

/// Faz 8 — yetkili sohbet avatarı: dönen neon çerçeve + parıltı.
class VoiceStaffChatAvatar extends StatefulWidget {
  const VoiceStaffChatAvatar({
    super.key,
    required this.rank,
    this.imageUrl,
    this.size = 32,
  });

  final VoiceStaffRank rank;
  final String? imageUrl;
  final double size;

  @override
  State<VoiceStaffChatAvatar> createState() => _VoiceStaffChatAvatarState();
}

class _VoiceStaffChatAvatarState extends State<VoiceStaffChatAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = VoiceStaffChatStyle.accentFor(widget.rank);
    final ring = 2.2;
    final inner = widget.size - ring * 2;
    final gradient = VoiceStaffChatStyle.ringGradient(widget.rank);

    return AnimatedBuilder(
      animation: Listenable.merge([_spin, _pulse]),
      builder: (context, child) {
        final glow = 8 + _pulse.value * 10;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: VoiceRoomTokens.neonGlow(accent, blur: glow),
          ),
          child: CustomPaint(
            painter: _RotatingRingPainter(
              progress: _spin.value,
              colors: gradient,
              strokeWidth: ring,
            ),
            child: Padding(
              padding: EdgeInsets.all(ring),
              child: ClipOval(
                child: SizedBox(
                  width: inner,
                  height: inner,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty
          ? CanlifalNetworkImage(
              url: widget.imageUrl!,
              width: inner,
              height: inner,
              fit: BoxFit.cover,
            )
          : ColoredBox(
              color: Colors.white.withValues(alpha: 0.08),
              child: Icon(
                Icons.person_rounded,
                size: inner * 0.5,
                color: accent.withValues(alpha: 0.85),
              ),
            ),
    );
  }
}

class _RotatingRingPainter extends CustomPainter {
  _RotatingRingPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
  });

  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(rect);
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      0,
      math.pi * 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RotatingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
