import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/site_animation_command.dart';
import '../../domain/site_animation_copy.dart';
import '../../domain/site_animation_type.dart';
import 'site_animation_entrance_theme.dart';

/// Tasarım referansı giriş kartı — `VoiceRoomEntryNotificationCard` düzeni + tier FX.
class SiteAnimationEntranceCard extends StatelessWidget {
  const SiteAnimationEntranceCard({
    super.key,
    required this.command,
    this.phase = 0,
    this.compact = false,
  });

  final SiteAnimationCommand command;
  final double phase;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = SiteAnimationEntranceTheme.resolve(
      animationId: command.animationId,
      tier: command.tier,
    );
    final subtitle = command.catalogLabel ??
        SiteAnimationCopy.subtitle(
          userName: command.userName,
          type: command.type,
          tier: command.tier,
        );
    final title = _titleLine(command);

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (theme.fx != SiteAnimationEntranceFx.none)
            Positioned.fill(
              child: CustomPaint(
                painter: _EntranceFxPainter(fx: theme.fx, phase: phase),
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: theme.gradient,
              ),
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.65),
                width: compact ? 1 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.borderColor.withValues(alpha: 0.35),
                  blurRadius: compact ? 10 : 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _LeadingAvatar(
                  theme: theme,
                  avatarUrl: command.avatarUrl,
                  compact: compact,
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 11 : 13,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 9 : 10,
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                if (theme.badge != null) ...[
                  const SizedBox(width: 6),
                  _BadgeChip(label: theme.badge!, compact: compact),
                ],
                if (theme.showChevron && !compact) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _titleLine(SiteAnimationCommand command) {
    final name = command.userName.trim().isEmpty
        ? 'Kullanıcı'
        : command.userName.trim();
    if (command.type == SiteAnimationType.hostSeat) {
      return '$name host koltuğuna geçti';
    }
    return '$name odaya giriş yaptı';
  }
}

class _LeadingAvatar extends StatelessWidget {
  const _LeadingAvatar({
    required this.theme,
    required this.avatarUrl,
    required this.compact,
  });

  final SiteAnimationEntranceTheme theme;
  final String? avatarUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 24.0 : 32.0;
    final url = avatarUrl?.trim();

    Widget inner;
    if (url != null && url.isNotEmpty) {
      inner = CircleAvatar(
        radius: size / 2 - 1,
        backgroundImage: NetworkImage(url),
      );
    } else {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.iconBg,
          border: Border.all(
            color: theme.iconColor.withValues(alpha: 0.65),
          ),
        ),
        child: Icon(
          theme.icon,
          color: theme.iconColor,
          size: compact ? 14 : 18,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.borderColor.withValues(alpha: 0.45),
            blurRadius: compact ? 6 : 10,
          ),
        ],
      ),
      child: inner,
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 7 : 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _EntranceFxPainter extends CustomPainter {
  _EntranceFxPainter({required this.fx, required this.phase});

  final SiteAnimationEntranceFx fx;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(fx.index + 11);

    switch (fx) {
      case SiteAnimationEntranceFx.goldDust:
        for (var i = 0; i < 18; i++) {
          final p = (phase + i * 0.05) % 1.0;
          paint.color = const Color(0xFFFFD54F).withValues(alpha: (1 - p) * 0.5);
          canvas.drawCircle(
            Offset(rng.nextDouble() * size.width, size.height * (1 - p)),
            1.5 + rng.nextDouble() * 2,
            paint,
          );
        }
      case SiteAnimationEntranceFx.fireCrown:
        paint.shader = RadialGradient(
          colors: [
            const Color(0xFFFF5722).withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(14),
          ),
          paint,
        );
      case SiteAnimationEntranceFx.starRing:
        for (var i = 0; i < 8; i++) {
          final a = phase * math.pi * 2 + i * math.pi / 4;
          paint.color = Colors.white.withValues(alpha: 0.35);
          canvas.drawCircle(
            Offset(
              size.width * 0.15 + math.cos(a) * 8,
              size.height * 0.5 + math.sin(a) * 8,
            ),
            2,
            paint,
          );
        }
      case SiteAnimationEntranceFx.lightning:
        paint.color = const Color(0xFF00D9D9).withValues(alpha: 0.35);
        final path = Path()
          ..moveTo(size.width * 0.82, 4)
          ..lineTo(size.width * 0.76, size.height * 0.45)
          ..lineTo(size.width * 0.88, size.height * 0.45)
          ..lineTo(size.width * 0.72, size.height - 4);
        canvas.drawPath(path, paint..strokeWidth = 2..style = PaintingStyle.stroke);
      case SiteAnimationEntranceFx.diamondBurst:
        paint.color = const Color(0xFF7DF9FF).withValues(alpha: 0.2);
        canvas.drawCircle(
          Offset(size.width * 0.12, size.height * 0.5),
          14 + math.sin(phase * math.pi * 2) * 3,
          paint,
        );
      case SiteAnimationEntranceFx.galaxyRing:
      case SiteAnimationEntranceFx.cosmicPortal:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        paint.color = const Color(0xFFC026D3).withValues(alpha: 0.35);
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(size.width * 0.12, size.height * 0.5),
            radius: 16,
          ),
          phase * math.pi,
          math.pi * 1.2,
          false,
          paint,
        );
      case SiteAnimationEntranceFx.spotlight:
        paint.shader = RadialGradient(
          center: const Alignment(0.5, -0.2),
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      case SiteAnimationEntranceFx.royalGate:
        paint.color = const Color(0xFFFFD54F).withValues(alpha: 0.25);
        canvas.drawRect(Rect.fromLTWH(0, 0, 6, size.height), paint);
        canvas.drawRect(
          Rect.fromLTWH(size.width - 6, 0, 6, size.height),
          paint,
        );
      case SiteAnimationEntranceFx.dragonEmperor:
        paint.color = const Color(0xFFFF6EC7).withValues(alpha: 0.2);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          paint,
        );
      case SiteAnimationEntranceFx.adminGalaxy:
        for (var i = 0; i < 12; i++) {
          paint.color = const Color(0xFF8B4DFF).withValues(alpha: 0.25);
          canvas.drawCircle(
            Offset(
              (i * 17.0 + phase * 40) % size.width,
              (i * 11.0) % size.height,
            ),
            1.5,
            paint,
          );
        }
      case SiteAnimationEntranceFx.hostCrown:
        paint.color = const Color(0xFFFFD54F).withValues(alpha: 0.3);
        canvas.drawCircle(
          Offset(size.width * 0.12, size.height * 0.5),
          12,
          paint,
        );
      case SiteAnimationEntranceFx.angelWings:
        paint.color = Colors.white.withValues(alpha: 0.15);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.08, size.height * 0.5),
            width: 18,
            height: 28,
          ),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.18, size.height * 0.5),
            width: 18,
            height: 28,
          ),
          paint,
        );
      case SiteAnimationEntranceFx.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _EntranceFxPainter oldDelegate) =>
      oldDelegate.fx != fx || oldDelegate.phase != phase;
}
