import 'dart:math' as math;

import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/auth/voice_staff_rank.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../theme/voice_room_tokens.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

/// Koltuk rütbesine göre çerçeve stili.
enum SeatAvatarRole {
  guest,
  vip,
  moderator,
  dj,
  host,
  admin,
}

abstract final class SeatAvatarRoleResolver {
  static SeatAvatarRole resolve({
    required ChatRoomPresence user,
    bool isHost = false,
    bool isRoomDj = false,
  }) {
    if (isHost) return SeatAvatarRole.host;
    final rank = VoiceStaffRankParser.resolve(
      username: user.nickname ?? user.name,
      role: null,
      chatRole: user.chatRole,
    );
    if (VoiceStaffRankParser.powerLevel(rank) >=
        VoiceStaffRankParser.powerLevel(VoiceStaffRank.admin)) {
      return SeatAvatarRole.admin;
    }
    if (user.chatRole == 'admin' || user.chatRole == 'founder') {
      return SeatAvatarRole.admin;
    }
    if (isRoomDj || user.chatRole == 'dj') return SeatAvatarRole.dj;
    if (VoiceStaffRankParser.canModerate(rank) || user.isBroadcaster) {
      return SeatAvatarRole.moderator;
    }
    if (VipTier.fromMembership(user.membership).isVip) {
      return SeatAvatarRole.vip;
    }
    return SeatAvatarRole.guest;
  }
}

abstract final class SeatAvatarStyle {
  static List<Color> ringGradient(SeatAvatarRole role, {required bool micOpen}) {
    if (!micOpen) {
      return [
        const Color(0xFF6B7280),
        const Color(0xFF4B5563),
        const Color(0xFF374151),
      ];
    }
    return switch (role) {
      SeatAvatarRole.admin => [
          const Color(0xFF7C4DFF),
          const Color(0xFF00E5FF),
          const Color(0xFFFFD54F),
          Colors.white.withValues(alpha: 0.85),
        ],
      SeatAvatarRole.host => [
          const Color(0xFFFFF3B0),
          VoiceRoomTokens.gold,
          const Color(0xFFFF8F00),
          Colors.white.withValues(alpha: 0.8),
        ],
      SeatAvatarRole.dj => [
          VoiceRoomTokens.neonBlue,
          VoiceRoomTokens.neonPink,
          VoiceRoomTokens.neonPurple,
        ],
      SeatAvatarRole.moderator => [
          VoiceRoomTokens.neonPurple,
          const Color(0xFFE040FB),
          VoiceRoomTokens.neonBlue,
        ],
      SeatAvatarRole.vip => [
          const Color(0xFFFFD54F),
          const Color(0xFFFF8A65),
          VoiceRoomTokens.neonPink,
        ],
      SeatAvatarRole.guest => [
          VoiceRoomTokens.neonPurple.withValues(alpha: 0.85),
          VoiceRoomTokens.neonBlue.withValues(alpha: 0.75),
          VoiceRoomTokens.neonPink.withValues(alpha: 0.65),
        ],
    };
  }

  static Color accent(SeatAvatarRole role, {required bool micOpen}) {
    if (!micOpen) return const Color(0xFF9CA3AF);
    return switch (role) {
      SeatAvatarRole.admin => const Color(0xFF00E5FF),
      SeatAvatarRole.host => VoiceRoomTokens.gold,
      SeatAvatarRole.dj => VoiceRoomTokens.neonBlue,
      SeatAvatarRole.moderator => VoiceRoomTokens.neonPurple,
      SeatAvatarRole.vip => VoiceRoomTokens.gold,
      SeatAvatarRole.guest => VoiceRoomTokens.neonPurple,
    };
  }

  static bool animatedRoleFrame(SeatAvatarRole role) =>
      role != SeatAvatarRole.guest;

  static double ringWidth(SeatAvatarRole role) => switch (role) {
        SeatAvatarRole.admin => 3.4,
        SeatAvatarRole.host => 3.2,
        SeatAvatarRole.dj => 2.8,
        SeatAvatarRole.moderator => 2.6,
        SeatAvatarRole.vip => 2.4,
        SeatAvatarRole.guest => 2.0,
      };
}

/// Faz 12 — tam yuvarlak cam koltuk: neon halka, mikrofon durumu, konuşma dalgası.
class VoiceSeatAvatarFrame extends StatefulWidget {
  const VoiceSeatAvatarFrame({
    super.key,
    this.imageUrl,
    required this.size,
    this.role = SeatAvatarRole.guest,
    this.speaking = false,
    this.micOpen = true,
  });

  final String? imageUrl;
  final double size;
  final SeatAvatarRole role;
  final bool speaking;
  final bool micOpen;

  @override
  State<VoiceSeatAvatarFrame> createState() => _VoiceSeatAvatarFrameState();
}

class _VoiceSeatAvatarFrameState extends State<VoiceSeatAvatarFrame>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant VoiceSeatAvatarFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimations();
  }

  void _syncAnimations() {
    if (widget.speaking && widget.micOpen) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
    if (widget.micOpen) {
      if (!_orbit.isAnimating) _orbit.repeat();
    } else {
      _orbit.stop();
      _orbit.value = 0;
    }
    if (SeatAvatarStyle.animatedRoleFrame(widget.role) && widget.micOpen) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (!widget.micOpen) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = SeatAvatarStyle.ringWidth(widget.role);
    final inner = widget.size - ring * 2;
    final accent = SeatAvatarStyle.accent(widget.role, micOpen: widget.micOpen);
    final gradient =
        SeatAvatarStyle.ringGradient(widget.role, micOpen: widget.micOpen);
    final pulseScale = widget.speaking && widget.micOpen ? 1 + _pulse.value * 0.08 : 1.0;
    final glowBlur = widget.micOpen
        ? (widget.speaking ? 12 + _pulse.value * 16 : 8.0)
        : 0.0;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _pulse, _orbit]),
        builder: (context, child) {
          return Transform.scale(
            scale: pulseScale,
            child: SizedBox(
              width: widget.size + 10,
              height: widget.size + 10,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.speaking && widget.micOpen)
                    CustomPaint(
                      size: Size(widget.size + 10, widget.size + 10),
                      painter: _SpeakingWavePainter(
                        progress: _pulse.value,
                        accent: accent,
                        baseRadius: widget.size / 2 + 2,
                      ),
                    ),
                  if (widget.micOpen)
                    CustomPaint(
                      size: Size(widget.size + 8, widget.size + 8),
                      painter: _OrbitingRingPainter(
                        progress: _orbit.value,
                        accent: accent,
                        radius: widget.size / 2 + 3,
                      ),
                    ),
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: glowBlur > 0
                          ? VoiceRoomTokens.neonGlow(
                              accent,
                              blur: glowBlur,
                            )
                          : null,
                    ),
                    child: CustomPaint(
                      painter: _NeonRingPainter(
                        progress: _spin.value,
                        colors: gradient,
                        strokeWidth: ring,
                        micOpen: widget.micOpen,
                        animated: SeatAvatarStyle.animatedRoleFrame(widget.role) &&
                            widget.micOpen,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(ring),
                        child: ClipOval(
                          child: SizedBox(
                            width: inner,
                            height: inner,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                child!,
                                _GlassOverlay(micOpen: widget.micOpen),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.role == SeatAvatarRole.host)
                    Positioned(
                      top: -2,
                      child: SizedBox(
                        width: widget.size * 0.32,
                        height: widget.size * 0.32,
                        child: Lottie.asset(
                          'assets/gifts/lottie/crown.json',
                          repeat: true,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.workspace_premium_rounded,
                            size: widget.size * 0.22,
                            color: widget.micOpen
                                ? VoiceRoomTokens.gold
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: _avatarImage(inner),
      ),
    );
  }

  Widget _avatarImage(double inner) {
    final url = widget.imageUrl?.trim();
    Widget image;
    if (url != null && url.isNotEmpty) {
      image = CanlifalNetworkImage(
        url: url,
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        thumbnailWidth: CanlifalImageUrls.avatarThumbnailWidth,
      );
    } else {
      image = ColoredBox(
        color: Colors.white.withValues(alpha: 0.08),
        child: Icon(
          Icons.person_rounded,
          size: inner * 0.48,
          color: widget.micOpen ? Colors.white54 : Colors.white30,
        ),
      );
    }
    if (!widget.micOpen) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.35, 0.35, 0.35, 0, 0,
          0.35, 0.35, 0.35, 0, 0,
          0.35, 0.35, 0.35, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: image,
      );
    }
    return image;
  }
}

class _GlassOverlay extends StatelessWidget {
  const _GlassOverlay({required this.micOpen});

  final bool micOpen;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: micOpen
                ? [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.transparent,
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.18),
                  ],
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.55, -0.65),
                radius: 0.95,
                colors: [
                  Colors.white.withValues(alpha: micOpen ? 0.28 : 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonRingPainter extends CustomPainter {
  _NeonRingPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
    required this.micOpen,
    required this.animated,
  });

  final double progress;
  final List<Color> colors;
  final double strokeWidth;
  final bool micOpen;
  final bool animated;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (animated) {
      paint.shader = SweepGradient(
        colors: [...colors, colors.first],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(rect);
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
    }

    canvas.drawCircle(
      rect.center,
      size.width / 2 - strokeWidth / 2,
      paint,
    );

    if (micOpen) {
      canvas.drawCircle(
        rect.center,
        size.width / 2 - strokeWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeonRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.micOpen != micOpen ||
      oldDelegate.animated != animated;
}

class _OrbitingRingPainter extends CustomPainter {
  _OrbitingRingPainter({
    required this.progress,
    required this.accent,
    required this.radius,
  });

  final double progress;
  final Color accent;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const segments = 3;
    for (var i = 0; i < segments; i++) {
      final start = progress * math.pi * 2 + i * (math.pi * 2 / segments);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi / 3.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SpeakingWavePainter extends CustomPainter {
  _SpeakingWavePainter({
    required this.progress,
    required this.accent,
    required this.baseRadius,
  });

  final double progress;
  final Color accent;
  final double baseRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final expand = phase * 10;
      final alpha = (1 - phase) * 0.4;
      canvas.drawCircle(
        center,
        baseRadius + expand,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: alpha),
      );
    }

    const barCount = 14;
    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * math.pi * 2;
      final amp = 2 + math.sin((progress * math.pi * 2) + i * 0.55) * 6;
      final inner = baseRadius - 1;
      final outer = inner + amp;
      final p1 = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.75),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeakingWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
