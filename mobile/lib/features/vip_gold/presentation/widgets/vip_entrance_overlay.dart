import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entrance_theme.dart';
import '../../domain/vip_tier.dart';
import '../../../../core/network/voice_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/entrance_effect_settings_provider.dart';
import '../theme/vip_gold_tokens.dart';
import 'vip_badge.dart';

/// Özel giriş animasyonu — sağdan sola kayan tam ekran FX (takım renkleri destekli).
class VipEntranceOverlay extends ConsumerStatefulWidget {
  const VipEntranceOverlay({
    super.key,
    required this.tier,
    required this.userName,
    this.profileImageUrl,
    this.theme,
    this.onFinished,
  });

  final VipTier tier;
  final String userName;
  final String? profileImageUrl;
  final EntranceTheme? theme;
  final VoidCallback? onFinished;

  @override
  ConsumerState<VipEntranceOverlay> createState() => VipEntranceOverlayState();
}

class VipEntranceOverlayState extends ConsumerState<VipEntranceOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  var _pass = 0;

  EntranceTheme get _theme => widget.theme ?? EntranceTheme.turkey;

  @override
  void initState() {
    super.initState();
    _startPass();
  }

  void _startPass() {
    final settings = ref.read(entranceEffectSettingsProvider);
    final user = ref.read(authControllerProvider).valueOrNull;
    VoiceEventLog.entryEffectStarted(userId: user?.id, tier: widget.tier.label);
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
        VoiceEventLog.entryEffectFinished(
          userId: ref.read(authControllerProvider).valueOrNull?.id,
        );
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

    final theme = _theme;
    final ctrl = _ctrl;
    if (ctrl == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(ctrl.value);
          final slideX = (1 - t) * MediaQuery.sizeOf(context).width * 0.55;
          final wobble = math.sin(t * math.pi * 3) * 8 * (1 - t);
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withValues(alpha: (1 - t) * 0.75),
              ),
              CustomPaint(
                painter: _ParticlePainter(
                  phase: ctrl.value,
                  accent: theme.primary,
                ),
                size: Size.infinite,
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(slideX + wobble, 0),
                  child: Opacity(
                    opacity: (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.7 + t * 0.35,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.profileImageUrl != null &&
                              widget.profileImageUrl!.trim().isNotEmpty)
                            CircleAvatar(
                              radius: 36,
                              backgroundImage:
                                  NetworkImage(widget.profileImageUrl!),
                            )
                          else if (theme.logoUrl != null &&
                              theme.logoUrl!.isNotEmpty)
                            ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: theme.logoUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.sports_soccer_rounded,
                                  size: 56,
                                  color: theme.iconColor,
                                ),
                              ),
                            )
                          else if (theme.flagEmoji != null)
                            Text(
                              theme.flagEmoji!,
                              style: const TextStyle(fontSize: 48),
                            )
                          else
                            Icon(
                              Icons.flight_land_rounded,
                              size: 64,
                              color: theme.iconColor,
                              shadows: [
                                Shadow(
                                  color: theme.glowColor,
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          ShaderMask(
                            shaderCallback: (b) =>
                                theme.titleGradient.createShader(b),
                            child: Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            theme.teamName != null
                                ? '${theme.teamName} taraftarı odaya giriş yaptı'
                                : 'odaya giriş yaptı',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          VipBadge(tier: widget.tier, animate: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (var i = 0; i < 36; i++) {
      final p = (phase + i * 0.03) % 1.0;
      final x = rng.nextDouble() * size.width;
      final y = size.height * (1 - p) + rng.nextDouble() * 40;
      paint.color = Color.lerp(
            accent,
            VipGoldTokens.goldMid,
            rng.nextDouble(),
          )!
          .withValues(alpha: (1 - p) * 0.65);
      canvas.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accent != accent;
}
