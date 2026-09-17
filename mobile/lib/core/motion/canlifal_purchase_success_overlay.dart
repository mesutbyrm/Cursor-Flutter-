import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/cds_fx.dart';
import 'canlifal_motion_tokens.dart';
import 'canlifal_motion_widgets.dart';

/// Gold / üyelik satın alma başarısı — kısa overlay (iş mantığı değişmez).
Future<void> showCanlifalPurchaseSuccessOverlay(
  BuildContext context, {
  required String title,
  String subtitle = 'Üyeliğiniz aktif',
  bool gold = true,
}) async {
  final fx = ProviderScope.containerOf(context).read(cdsFxProvider);
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Başarılı',
    barrierColor: Colors.black54,
    transitionDuration: CanlifalMotionTokens.normal,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: CanlifalMotionTokens.easeOut,
        reverseCurve: CanlifalMotionTokens.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: gold
                        ? [
                            const Color(0xFF2A1F0A),
                            const Color(0xFF120A1E),
                          ]
                        : [
                            const Color(0xFF1A1030),
                            const Color(0xFF120A1E),
                          ],
                  ),
                  border: Border.all(
                    color: gold
                        ? const Color(0xFFFFD54F).withValues(alpha: 0.45)
                        : Colors.white24,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gold
                          ? const Color(0xFFFFD54F).withValues(alpha: 0.25)
                          : Colors.black45,
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CanlifalEntranceFadeSlide(
                      delay: const Duration(milliseconds: 80),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 64,
                        color: gold
                            ? const Color(0xFFFFD54F)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                    if (gold && !fx.decorativeDisabled) ...[
                      const SizedBox(height: 20),
                      const _GoldSparkleRow(),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: gold
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF9B4DFF),
                        foregroundColor: gold ? Colors.black : Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Harika',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _GoldSparkleRow extends StatelessWidget {
  const _GoldSparkleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CanlifalEntranceFadeSlide(
              delay: Duration(milliseconds: 120 + i * 60),
              slideY: 0.02,
              child: Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFFFFD54F).withValues(alpha: 0.5 + i * 0.1),
              ),
            ),
          ),
      ],
    );
  }
}
