import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entrance_theme.dart';
import '../../domain/vip_tier.dart';
import '../providers/entrance_effect_settings_provider.dart';
import 'team_emblem_avatar.dart';
import 'vip_badge.dart';

/// Gold+ giriş — takım renkleri ve amblem ile üstten kayarak geçer.
class GoldTeamTopEntranceBanner extends ConsumerStatefulWidget {
  const GoldTeamTopEntranceBanner({
    super.key,
    required this.userName,
    required this.tier,
    required this.theme,
    this.profileImageUrl,
    this.subtitle,
    this.topInset = 0,
    this.onFinished,
  });

  final String userName;
  final VipTier tier;
  final EntranceTheme theme;
  final String? profileImageUrl;
  final String? subtitle;
  final double topInset;
  final VoidCallback? onFinished;

  @override
  ConsumerState<GoldTeamTopEntranceBanner> createState() =>
      _GoldTeamTopEntranceBannerState();
}

class _GoldTeamTopEntranceBannerState
    extends ConsumerState<GoldTeamTopEntranceBanner>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  var _pass = 0;

  @override
  void initState() {
    super.initState();
    _startPass();
  }

  void _startPass() {
    final settings = ref.read(entranceEffectSettingsProvider);
    _ctrl?.dispose();
    _ctrl = AnimationController(
      vsync: this,
      duration: settings.animationDuration,
    )..forward().then((_) {
        final maxPass = settings.passCount.clamp(1, 3);
        if (!mounted) return;
        if (_pass + 1 < maxPass) {
          _pass++;
          _startPass();
          return;
        }
        widget.onFinished?.call();
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tier.hasEntranceFx) return const SizedBox.shrink();
    final ctrl = _ctrl;
    if (ctrl == null) return const SizedBox.shrink();

    final theme = widget.theme;
    final subtitle = widget.subtitle ??
        (theme.teamName != null
            ? '${theme.teamName} taraftarı odaya giriş yaptı'
            : 'odaya giriş yaptı');

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(ctrl.value);
          final enter = t < 0.35 ? t / 0.35 : 1.0;
          final exit = t > 0.72 ? (t - 0.72) / 0.28 : 0.0;
          final slideY = -120 * (1 - enter) - 48 * exit;
          final opacity = (1 - exit).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (exit < 0.5)
                Container(
                  color: Colors.black.withValues(alpha: 0.35 * (1 - exit)),
                ),
              Positioned(
                top: widget.topInset + MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, slideY),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            theme.primary.withValues(alpha: 0.92),
                            theme.secondary.withValues(alpha: 0.75),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                        ),
                        border: Border.all(
                          color: theme.borderColor.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.glowColor,
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            TeamEmblemAvatar(theme: theme, size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (b) =>
                                        theme.titleGradient.createShader(b),
                                    child: Text(
                                      widget.userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            VipBadge(tier: widget.tier, animate: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (t > 0.2 && t < 0.75)
                CustomPaint(
                  painter: _SparkPainter(
                    phase: t,
                    accent: theme.primary,
                  ),
                  size: Size.infinite,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(7);
    for (var i = 0; i < 24; i++) {
      final p = (phase + i * 0.04) % 1.0;
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.15 + rng.nextDouble() * 80;
      paint.color = accent.withValues(alpha: (1 - p) * 0.5);
      canvas.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
