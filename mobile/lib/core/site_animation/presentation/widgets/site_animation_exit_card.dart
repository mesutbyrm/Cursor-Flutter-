import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/site_animation_command.dart';
import '../../domain/site_animation_copy.dart';
import '../../domain/site_animation_tier.dart';
import 'site_animation_entrance_theme.dart';

/// Çıkış bildirimi — giriş kartı düzeni + dissolve / slide-out FX.
class SiteAnimationExitCard extends StatelessWidget {
  const SiteAnimationExitCard({
    super.key,
    required this.command,
    this.phase = 0,
  });

  final SiteAnimationCommand command;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final entranceTheme = SiteAnimationEntranceTheme.resolve(
      animationId: command.animationId,
      tier: command.tier,
    );
    final subtitle = command.catalogLabel ??
        SiteAnimationCopy.subtitle(
          userName: command.userName,
          type: command.type,
          tier: command.tier,
        );
    final dissolve = Curves.easeIn.transform(phase.clamp(0.0, 1.0));

    return RepaintBoundary(
      child: Opacity(
        opacity: 1 - dissolve * 0.35,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ExitDissolvePainter(
                  tier: command.tier,
                  phase: phase,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: entranceTheme.gradient
                      .map((c) => c.withValues(alpha: 0.85))
                      .toList(),
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: entranceTheme.borderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: entranceTheme.iconColor.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitDissolvePainter extends CustomPainter {
  _ExitDissolvePainter({required this.tier, required this.phase});

  final SiteAnimationTier tier;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(tier.index + 7);
    final color = switch (tier) {
      SiteAnimationTier.gold => const Color(0xFFFFD54F),
      SiteAnimationTier.diamond => const Color(0xFF7DF9FF),
      SiteAnimationTier.svip => const Color(0xFFFF6EC7),
      SiteAnimationTier.admin => const Color(0xFF8B4DFF),
      _ => const Color(0xFFB388FF),
    };

    for (var i = 0; i < 14; i++) {
      final p = (phase + i * 0.06) % 1.0;
      paint.color = color.withValues(alpha: (1 - p) * 0.35);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, size.height * (1 - p)),
        1.2 + rng.nextDouble() * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExitDissolvePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.tier != tier;
}
