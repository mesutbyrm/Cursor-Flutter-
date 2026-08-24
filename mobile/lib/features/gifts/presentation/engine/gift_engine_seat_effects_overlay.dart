import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/gift_engine_models.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/gift_engine_parser.dart';

/// Koltuk efektleri — Glow, Border, Shake, Pulse, Particle (backend listesi).
class GiftEngineSeatEffectsOverlay extends StatefulWidget {
  const GiftEngineSeatEffectsOverlay({
    super.key,
    required this.event,
    this.seatCount = 11,
  });

  final LiveGiftEvent? event;
  final int seatCount;

  @override
  State<GiftEngineSeatEffectsOverlay> createState() =>
      _GiftEngineSeatEffectsOverlayState();
}

class _GiftEngineSeatEffectsOverlayState extends State<GiftEngineSeatEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    if (ev == null) return const SizedBox.shrink();

    final config = GiftEngineParser.fromEvent(ev);
    if (config.seatEffects.isEmpty) return const SizedBox.shrink();

    final seatIndex = ev.seatIndex ?? 0;
    if (seatIndex < 0 || seatIndex >= widget.seatCount) {
      return const SizedBox.shrink();
    }

    final w = MediaQuery.sizeOf(context).width;
    final cols = 4;
    final col = seatIndex % cols;
    final row = seatIndex ~/ cols;
    final left = 12 + col * (w - 24) / cols;
    final top = 108.0 + row * 84;
    final color = _parseColor(config.effectColor) ?? const Color(0xFFB388FF);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: 64,
              height: 64,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  var scale = 1.0;
                  var offset = Offset.zero;
                  if (config.seatEffects.contains(GiftSeatEffect.pulse)) {
                    scale = 1.0 + _pulse.value * 0.12;
                  }
                  if (config.seatEffects.contains(GiftSeatEffect.shake)) {
                    offset = Offset(
                      math.sin(_pulse.value * math.pi * 4) * 3,
                      0,
                    );
                  }
                  return Transform.translate(
                    offset: offset,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: _SeatEffectVisual(
                  effects: config.seatEffects,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(v);
  }
}

class _SeatEffectVisual extends StatelessWidget {
  const _SeatEffectVisual({
    required this.effects,
    required this.color,
  });

  final List<GiftSeatEffect> effects;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: effects.contains(GiftSeatEffect.border)
            ? Border.all(color: color, width: 3)
            : null,
        boxShadow: [
          if (effects.contains(GiftSeatEffect.glow))
            BoxShadow(
              color: color.withValues(alpha: 0.75),
              blurRadius: 18,
              spreadRadius: 4,
            ),
        ],
      ),
      child: effects.contains(GiftSeatEffect.particle)
          ? Center(
              child: Text('✨', style: TextStyle(fontSize: 28, color: color)),
            )
          : null,
    );
  }
}
