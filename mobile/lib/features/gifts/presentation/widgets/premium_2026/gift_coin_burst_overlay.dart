import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Jeton yağmuru — hediye gönderiminde kısa süreli coin burst.
class GiftCoinBurstOverlay extends StatefulWidget {
  const GiftCoinBurstOverlay({
    super.key,
    required this.active,
    this.coinCount = 12,
  });

  final bool active;
  final int coinCount;

  @override
  State<GiftCoinBurstOverlay> createState() => GiftCoinBurstOverlayState();
}

class GiftCoinBurstOverlayState extends State<GiftCoinBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _coins = <_CoinParticle>[];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  void burst({int? count}) {
    if (!mounted) return;
    final n = count ?? widget.coinCount;
    setState(() {
      _coins.clear();
      for (var i = 0; i < n; i++) {
        _coins.add(_CoinParticle(
          x: 0.2 + _rand.nextDouble() * 0.6,
          delay: _rand.nextDouble() * 0.25,
          spin: _rand.nextDouble() * pi,
        ));
      }
    });
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && _coins.isEmpty) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            children: [
              for (final c in _coins)
                if ((_ctrl.value - c.delay).clamp(0.0, 1.0) > 0)
                  Positioned(
                    left: size.width * c.x,
                    top: size.height * (0.35 - ((_ctrl.value - c.delay).clamp(0.0, 1.0)) * 0.45),
                    child: Opacity(
                      opacity: (1 - ((_ctrl.value - c.delay).clamp(0.0, 1.0))).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: c.spin + _ctrl.value * 4,
                        child: Icon(
                          Icons.monetization_on_rounded,
                          color: AppColors.coinGold.withValues(
                            alpha: 0.85 + _rand.nextDouble() * 0.15,
                          ),
                          size: 18 + _rand.nextDouble() * 10,
                          shadows: [
                            Shadow(
                              color: AppColors.coinGold.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
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

class _CoinParticle {
  _CoinParticle({
    required this.x,
    required this.delay,
    required this.spin,
  });

  final double x;
  final double delay;
  final double spin;
}
