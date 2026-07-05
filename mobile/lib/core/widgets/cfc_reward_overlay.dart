import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme_colors.dart';

/// Ödüllü reklam sonrası ortada şekilli CFC kazanç bildirimi.
class CfcRewardOverlay {
  CfcRewardOverlay._();

  static Future<void> show(
    BuildContext context, {
    int amount = 10,
    String label = 'CFC jeton',
    Duration displayFor = const Duration(seconds: 2),
  }) async {
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ödül',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, _) {
        Future<void>.delayed(displayFor, () {
          if (ctx.mounted) Navigator.of(ctx).maybePop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _RewardCard(amount: amount, label: label),
          ),
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.amount, required this.label});

  final int amount;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1848),
                Color(0xFF120A22),
              ],
            ),
            border: Border.all(
              color: AppThemeColors.accentPink.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.45),
                blurRadius: 36,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppThemeColors.coinGold.withValues(alpha: 0.9),
                      AppThemeColors.accentPink.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.diamond_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.06, 1.06),
                    duration: 900.ms,
                  ),
              const SizedBox(height: 18),
              Text(
                '+$amount $label',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'kazandınız',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reklamı tamamladığınız için teşekkürler',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .scale(
          begin: const Offset(0.82, 0.82),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 420.ms,
        );
  }
}
