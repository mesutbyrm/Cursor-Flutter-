import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// TikTok tarzı yüzen kalpler / emoji parçacıkları.
class FloatingGiftParticles extends StatefulWidget {
  const FloatingGiftParticles({
    super.key,
    this.emojis = const ['💖', '🌹', '⭐'],
    this.spawnFromGiftId,
  });

  final List<String> emojis;
  final String? spawnFromGiftId;

  @override
  State<FloatingGiftParticles> createState() => FloatingGiftParticlesState();
}

class FloatingGiftParticlesState extends State<FloatingGiftParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _particles = <_Particle>[];
  final _rand = Random();
  Timer? _spawn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _spawn = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        _particles.add(_Particle(
          id: _rand.nextInt(1 << 30),
          emoji: widget.emojis[_rand.nextInt(widget.emojis.length)],
          left: 0.5 + _rand.nextDouble() * 0.42,
          phase: _rand.nextDouble(),
        ));
        if (_particles.length > 14) _particles.removeAt(0);
      });
    });
  }

  void burst(String emoji, {int count = 8}) {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < count; i++) {
        _particles.add(_Particle(
          id: _rand.nextInt(1 << 30),
          emoji: emoji,
          left: 0.35 + _rand.nextDouble() * 0.5,
          phase: _rand.nextDouble(),
        ));
      }
    });
  }

  @override
  void dispose() {
    _spawn?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            for (final p in _particles)
              Positioned(
                left: MediaQuery.sizeOf(context).width * p.left,
                bottom: h * 0.12 + ((_ctrl.value + p.phase) % 1.0) * h * 0.5,
                child: Opacity(
                  opacity: (1 - ((_ctrl.value + p.phase) % 1.0)).clamp(0.0, 1.0),
                  child: Text(
                    p.emoji,
                    style: TextStyle(
                      fontSize: 18 + ((_ctrl.value + p.phase) % 1.0) * 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.id,
    required this.emoji,
    required this.left,
    required this.phase,
  });
  final int id;
  final String emoji;
  final double left;
  final double phase;
}
