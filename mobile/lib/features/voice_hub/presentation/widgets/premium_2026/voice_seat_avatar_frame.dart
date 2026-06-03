import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Koltuk avatarı — host ve misafir için ayrı şekilli çerçeve; görsel tam oturur.
class VoiceSeatAvatarFrame extends StatelessWidget {
  const VoiceSeatAvatarFrame({
    super.key,
    this.imageUrl,
    required this.size,
    this.isHost = false,
    this.speaking = false,
  });

  final String? imageUrl;
  final double size;
  final bool isHost;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final border = isHost ? 3.2 : 2.4;
    final inner = size - border * 2;
    final gradient = isHost
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD54F),
              Color(0xFFFFB300),
              Color(0xFFFF8F00),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VoiceRoomTokens.neonPurple.withValues(alpha: 0.95),
              VoiceRoomTokens.neonBlue.withValues(alpha: 0.85),
              VoiceRoomTokens.neonPink.withValues(alpha: 0.7),
            ],
          );

    final glow = speaking
        ? [
            BoxShadow(
              color: (isHost ? VoiceRoomTokens.gold : VoiceRoomTokens.neonPink)
                  .withValues(alpha: 0.55),
              blurRadius: isHost ? 16 : 12,
              spreadRadius: 1,
            ),
          ]
        : isHost
            ? [
                BoxShadow(
                  color: VoiceRoomTokens.gold.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ]
            : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: glow,
      ),
      child: CustomPaint(
        painter: _FrameBorderPainter(
          gradient: gradient,
          borderWidth: border,
          host: isHost,
        ),
        child: Padding(
          padding: EdgeInsets.all(border),
          child: ClipPath(
            clipper: isHost ? _HostAvatarClipper() : _GuestAvatarClipper(),
            child: SizedBox(
              width: inner,
              height: inner,
              child: _avatarImage(inner),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarImage(double inner) {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.08),
      child: Icon(
        Icons.person_rounded,
        size: inner * 0.48,
        color: Colors.white54,
      ),
    );
  }
}

class _FrameBorderPainter extends CustomPainter {
  _FrameBorderPainter({
    required this.gradient,
    required this.borderWidth,
    required this.host,
  });

  final Gradient gradient;
  final double borderWidth;
  final bool host;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = host
        ? _hostPath(size)
        : _guestPath(size);
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(outer, paint);
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

  Path _guestPath(Size size) {
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
  bool shouldRepaint(covariant _FrameBorderPainter oldDelegate) =>
      oldDelegate.host != host || oldDelegate.borderWidth != borderWidth;
}

class _HostAvatarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
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

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GuestAvatarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
