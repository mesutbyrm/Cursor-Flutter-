import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
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

/// Profil resmini tam kaplayan animasyonlu koltuk çerçevesi.
class VoiceSeatAvatarFrame extends StatefulWidget {
  const VoiceSeatAvatarFrame({
    super.key,
    this.imageUrl,
    required this.size,
    this.role = SeatAvatarRole.guest,
    this.speaking = false,
  });

  final String? imageUrl;
  final double size;
  final SeatAvatarRole role;
  final bool speaking;

  @override
  State<VoiceSeatAvatarFrame> createState() => _VoiceSeatAvatarFrameState();
}

class _VoiceSeatAvatarFrameState extends State<VoiceSeatAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = _borderWidth;
    final inner = widget.size - border * 2;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_animatedRing) _animatedRingWidget(),
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SeatFramePainter(
                role: widget.role,
                speaking: widget.speaking,
                spin: _spin.value,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(border),
              child: ClipPath(
                clipper: _clipperForRole(),
                child: SizedBox(
                  width: inner,
                  height: inner,
                  child: _avatarImage(inner),
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
                  ),
                ),
              ),
            if (widget.role == SeatAvatarRole.dj && widget.speaking)
              Positioned(
                bottom: 0,
                right: 0,
                child: _miniEq(),
              ),
          ],
        ),
      ),
    );
  }

  bool get _animatedRing =>
      widget.role == SeatAvatarRole.moderator ||
      widget.role == SeatAvatarRole.admin ||
      widget.role == SeatAvatarRole.vip;

  double get _borderWidth => switch (widget.role) {
        SeatAvatarRole.admin => 3.6,
        SeatAvatarRole.host => 3.4,
        SeatAvatarRole.dj => 3.0,
        SeatAvatarRole.moderator => 2.8,
        SeatAvatarRole.vip => 2.6,
        SeatAvatarRole.guest => 2.0,
      };

  Widget _animatedRingWidget() {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size + 6, widget.size + 6),
          painter: _ParticleRingPainter(
            role: widget.role,
            t: _spin.value,
            speaking: widget.speaking,
          ),
        );
      },
    );
  }

  CustomClipper<Path> _clipperForRole() => switch (widget.role) {
        SeatAvatarRole.host || SeatAvatarRole.admin => _HostClipper(),
        SeatAvatarRole.dj || SeatAvatarRole.moderator => _HexClipper(),
        _ => _RoundedClipper(),
      };

  Widget _avatarImage(double inner) {
    final url = widget.imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        memCacheWidth: (inner * 2).round(),
      );
    }
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.08),
      child: Icon(Icons.person_rounded, size: inner * 0.48, color: Colors.white54),
    );
  }

  Widget _miniEq() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final h = 6.0 + math.sin(_spin.value * math.pi * 4 + i) * 4;
        return Container(
          width: 3,
          height: h,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: VoiceRoomTokens.neonBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _SeatFramePainter extends CustomPainter {
  _SeatFramePainter({
    required this.role,
    required this.speaking,
    required this.spin,
  });

  final SeatAvatarRole role;
  final bool speaking;
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _outerPath(size);
    final colors = _gradientColors();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = switch (role) {
        SeatAvatarRole.admin => 3.6,
        SeatAvatarRole.host => 3.4,
        SeatAvatarRole.dj => 3.0,
        SeatAvatarRole.moderator => 2.8,
        SeatAvatarRole.vip => 2.6,
        SeatAvatarRole.guest => 2.0,
      };
    canvas.drawPath(path, paint);
    if (speaking) {
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.first.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  List<Color> _gradientColors() => switch (role) {
        SeatAvatarRole.admin => [
            const Color(0xFF7C4DFF),
            const Color(0xFF00E5FF),
            const Color(0xFFFFD54F),
          ],
        SeatAvatarRole.host => [
            const Color(0xFFFFD54F),
            const Color(0xFFFFB300),
            const Color(0xFFFF8F00),
          ],
        SeatAvatarRole.dj => [
            VoiceRoomTokens.neonBlue,
            VoiceRoomTokens.neonPink,
          ],
        SeatAvatarRole.moderator => [
            VoiceRoomTokens.neonPurple,
            const Color(0xFFE040FB),
          ],
        SeatAvatarRole.vip => [
            const Color(0xFFFFD54F),
            const Color(0xFFFF8A65),
          ],
        SeatAvatarRole.guest => [
            VoiceRoomTokens.neonPurple.withValues(alpha: 0.8),
            VoiceRoomTokens.neonBlue.withValues(alpha: 0.6),
          ],
      };

  Path _outerPath(Size size) {
    if (role == SeatAvatarRole.host || role == SeatAvatarRole.admin) {
      return _hostPath(size);
    }
    if (role == SeatAvatarRole.dj || role == SeatAvatarRole.moderator) {
      return _hexPath(size);
    }
    return _roundPath(size);
  }

  Path _hostPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.22;
    return Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w - r, r * 0.55)
      ..lineTo(w - r * 0.35, h)
      ..lineTo(r * 0.35, h)
      ..lineTo(r, r * 0.55)
      ..close();
  }

  Path _hexPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final rad = w / 2 - 1;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - math.pi / 2;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _roundPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.28;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SeatFramePainter old) =>
      old.role != role || old.speaking != speaking || old.spin != spin;
}

class _ParticleRingPainter extends CustomPainter {
  _ParticleRingPainter({
    required this.role,
    required this.t,
    required this.speaking,
  });

  final SeatAvatarRole role;
  final double t;
  final bool speaking;

  @override
  void paint(Canvas canvas, Size size) {
    if (!speaking && role != SeatAvatarRole.admin && role != SeatAvatarRole.moderator) {
      return;
    }
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rad = size.width / 2;
    final color = switch (role) {
      SeatAvatarRole.admin => const Color(0xFF00E5FF),
      SeatAvatarRole.moderator => const Color(0xFFE040FB),
      SeatAvatarRole.vip => const Color(0xFFFFD54F),
      _ => Colors.white,
    };
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    for (var i = 0; i < 8; i++) {
      final a = t * math.pi * 2 + i * (math.pi / 4);
      final pr = rad + 2 + math.sin(t * math.pi * 2 + i) * 2;
      canvas.drawCircle(
        Offset(cx + math.cos(a) * pr, cy + math.sin(a) * pr),
        2.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleRingPainter old) => old.t != t;
}

class _HostClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _SeatFramePainter(
        role: SeatAvatarRole.host,
        speaking: false,
        spin: 0,
      )._hostPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _SeatFramePainter(
        role: SeatAvatarRole.dj,
        speaking: false,
        spin: 0,
      )._hexPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RoundedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _SeatFramePainter(
        role: SeatAvatarRole.guest,
        speaking: false,
        spin: 0,
      )._roundPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
