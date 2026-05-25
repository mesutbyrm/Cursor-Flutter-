import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../domain/entities/chat_room_presence.dart';
import '../../../theme/voice_room_tokens.dart';

/// Cyber HUD oyuncu çerçevesi — 1v1 veya takım lideri.
String _fmtScore(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class PkPlayerHudFrame extends StatelessWidget {
  const PkPlayerHudFrame({
    super.key,
    required this.user,
    required this.accent,
    required this.label,
    this.isLeading = false,
    this.onFollow,
    this.score = 0,
  });

  final ChatRoomPresence? user;
  final Color accent;
  final String label;
  final bool isLeading;
  final VoidCallback? onFollow;
  final int score;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'PLAYER';
    final img = user?.image;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: CustomPaint(
        painter: _HudFramePainter(accent: accent, glow: isLeading),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 3),
                      boxShadow: VoiceRoomTokens.neonGlow(accent, blur: 20),
                    ),
                    child: ClipOval(
                      child: img != null && img.isNotEmpty
                          ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                          : ColoredBox(
                              color: Colors.white10,
                              child: Icon(Icons.person, size: 52, color: accent),
                            ),
                    ),
                  ),
                  if (isLeading)
                    Positioned(
                      top: 0,
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: VoiceRoomTokens.gold,
                        size: 28,
                        shadows: VoiceRoomTokens.goldGlow(blur: 8)
                            .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                            .toList(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: accent.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: VoiceRoomTokens.gold),
                  const SizedBox(width: 4),
                  Text(
                    _fmtScore(score),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (onFollow != null) ...[
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: onFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent.withValues(alpha: 0.85),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  ),
                  child: const Text('Takip', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

class _HudFramePainter extends CustomPainter {
  _HudFramePainter({required this.accent, required this.glow});

  final Color accent;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(16, 0);
    path.lineTo(w - 16, 0);
    path.lineTo(w, 16);
    path.lineTo(w, h - 16);
    path.lineTo(w - 16, h);
    path.lineTo(16, h);
    path.lineTo(0, h - 16);
    path.lineTo(0, 16);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = glow ? 2.2 : 1.4
      ..color = accent.withValues(alpha: glow ? 0.95 : 0.65);
    canvas.drawPath(path, stroke);

    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      final p = Offset(w / 2 + math.cos(a) * w * 0.46, h / 2 + math.sin(a) * h * 0.46);
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 6, height: 6),
        Paint()..color = i.isEven ? accent : Colors.white70,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HudFramePainter old) =>
      old.accent != accent || old.glow != glow;
}
