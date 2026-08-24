import 'package:flutter/material.dart';

import '../../domain/lucky_gift_entities.dart';

/// Spin sonucu — çark/kutu açılış animasyonu + ödül gösterimi.
Future<void> showLuckyGiftSpinOverlay(
  BuildContext context, {
  required LuckyGiftSpinResult result,
  String? giftName,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Şanslı hediye sonucu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, anim1, anim2) {
      return _LuckyGiftSpinOverlay(
        result: result,
        giftName: giftName,
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _LuckyGiftSpinOverlay extends StatefulWidget {
  const _LuckyGiftSpinOverlay({
    required this.result,
    this.giftName,
  });

  final LuckyGiftSpinResult result;
  final String? giftName;

  @override
  State<_LuckyGiftSpinOverlay> createState() => _LuckyGiftSpinOverlayState();
}

class _LuckyGiftSpinOverlayState extends State<_LuckyGiftSpinOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _revealed = true);
        }
      });
    _spin.forward();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final color = r.resolveColor();
    final gift = widget.giftName?.trim();

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.92),
                  const Color(0xFF1E1B4B).withValues(alpha: 0.96),
                ],
              ),
              border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: r.isJackpot ? 36 : 20,
                  spreadRadius: r.isJackpot ? 4 : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_revealed)
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 3.0).animate(
                      CurvedAnimation(parent: _spin, curve: Curves.easeInOut),
                    ),
                    child: Text(
                      r.icon ?? '🎁',
                      style: const TextStyle(fontSize: 64),
                    ),
                  )
                else ...[
                  Text(
                    r.isJackpot ? '👑 JACKPOT!' : (r.icon ?? '🍀'),
                    style: TextStyle(
                      fontSize: r.isJackpot ? 48 : 56,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.tierName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (gift != null && gift.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      gift,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '×${r.multiplier.toStringAsFixed(r.multiplier % 1 == 0 ? 0 : 1)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${r.wonJetons} jeton kazandınız',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    r.netJetons >= 0
                        ? 'Net +${r.netJetons} jeton'
                        : 'Net ${r.netJetons} jeton',
                    style: TextStyle(
                      fontSize: 13,
                      color: r.netJetons >= 0
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tamam', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
