import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../ultra_premium/ultra_fortune_liquid_surface.dart';
import '../ultra_premium/ultra_fortune_tokens.dart';

/// Premium «Falını Aç» CTA — glow, haptic, shimmer.
class PremiumFortuneOpenButton extends StatefulWidget {
  const PremiumFortuneOpenButton({
    super.key,
    required this.accent,
    required this.onPressed,
    this.enabled = true,
  });

  final Color accent;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<PremiumFortuneOpenButton> createState() =>
      _PremiumFortuneOpenButtonState();
}

class _PremiumFortuneOpenButtonState extends State<PremiumFortuneOpenButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  void _tap() {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, __) {
          final pulse = 0.5 + 0.5 * _glow.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.35 * pulse),
                  blurRadius: 24 + 12 * pulse,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.2 * pulse),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _tap,
                borderRadius: BorderRadius.circular(28),
                child: UltraFortuneLiquidSurface(
                  goldAccent: true,
                  borderRadius: BorderRadius.circular(28),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Lottie.asset(
                          'assets/gifts/lottie/star.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '✨ Falını Aç',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AI fal üretimi sırasında tam ekran yükleme — dönen kartlar.
class PremiumFortuneLoadingOverlay extends StatefulWidget {
  const PremiumFortuneLoadingOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  State<PremiumFortuneLoadingOverlay> createState() =>
      _PremiumFortuneLoadingOverlayState();
}

class _PremiumFortuneLoadingOverlayState extends State<PremiumFortuneLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60A0118),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _spin,
                builder: (_, __) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Transform.rotate(
                            angle: _spin.value * math.pi * 2 + i * 2.1,
                            child: Transform.translate(
                              offset: Offset(0, -36 + i * 4.0),
                              child: _TarotCardFace(
                                accent: widget.accent,
                                label: ['I', 'X', '☽'][i],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _ShimmerBar(accent: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarotCardFace extends StatelessWidget {
  const _TarotCardFace({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.9),
            const Color(0xFF1A0F2E),
          ],
        ),
        border: Border.all(color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 12,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar({required this.accent});

  final Color accent;

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          height: 4,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          alignment: Alignment(_ctrl.value * 2 - 1, 0),
          child: Container(
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  widget.accent.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void showPremiumFortuneLoading({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Color accent,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (_) => PopScope(
      canPop: false,
      child: PremiumFortuneLoadingOverlay(
        title: title,
        subtitle: subtitle,
        accent: accent,
      ),
    ),
  );
}
