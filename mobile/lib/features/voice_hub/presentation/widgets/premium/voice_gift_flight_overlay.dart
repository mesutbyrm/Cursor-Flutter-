import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../../../live/domain/entities/live_gift_event.dart';
import '../../theme/voice_room_tokens.dart';

/// TikTok tarzı sürekli uçan hediye animasyonu.
class VoiceGiftFlightOverlay extends StatefulWidget {
  const VoiceGiftFlightOverlay({
    super.key,
    required this.events,
    required this.onFinished,
    this.enabled = true,
  });

  final List<LiveGiftEvent> events;
  final void Function(String eventId) onFinished;
  final bool enabled;

  @override
  State<VoiceGiftFlightOverlay> createState() => _VoiceGiftFlightOverlayState();
}

class _VoiceGiftFlightOverlayState extends State<VoiceGiftFlightOverlay>
    with TickerProviderStateMixin {
  final _rand = Random();
  final _active = <_FlightItem>[];
  final _ambient = <_AmbientParticle>[];
  Timer? _ambientTimer;
  final Set<String> _started = {};

  @override
  void initState() {
    super.initState();
    _ambientTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!widget.enabled || !mounted) return;
      if (_active.isEmpty && _ambient.isEmpty) return;
      setState(() {
        _ambient.add(_AmbientParticle(
          id: _rand.nextInt(1 << 30),
          emoji: const ['✨', '💖', '🌹', '⭐', '🎁'][_rand.nextInt(5)],
          x: _rand.nextDouble(),
        ));
        if (_ambient.length > 8) _ambient.removeAt(0);
      });
    });
  }

  @override
  void didUpdateWidget(covariant VoiceGiftFlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final e in widget.events) {
      if (_started.add(e.id)) _spawnFlight(e);
    }
  }

  void _spawnFlight(LiveGiftEvent e) {
    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + _rand.nextInt(800)),
    );
    final item = _FlightItem(
      event: e,
      controller: ctrl,
      startX: 0.15 + _rand.nextDouble() * 0.7,
      wobble: _rand.nextDouble() * 0.15,
    );
    _active.add(item);
    ctrl.forward().then((_) {
      if (!mounted) return;
      widget.onFinished(e.id);
      setState(() {
        _active.remove(item);
        ctrl.dispose();
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    for (final a in _active) {
      a.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final p in _ambient)
            _AmbientWidget(
              particle: p,
              height: size.height,
              width: size.width,
            ),
          for (final f in _active)
            AnimatedBuilder(
              animation: f.controller,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(f.controller.value);
                final x = size.width * (f.startX + sin(t * pi) * f.wobble);
                final y = size.height * (0.88 - t * 0.72);
                final scale = 0.6 + t * 0.9;
                return Positioned(
                  left: x - 28,
                  top: y,
                  child: Opacity(
                    opacity: (1 - t * 0.85).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: _GiftFlightBubble(event: f.event),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GiftFlightBubble extends StatelessWidget {
  const _GiftFlightBubble({required this.event});

  final LiveGiftEvent event;

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiFor(event);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VoiceRoomTokens.neonPink.withValues(alpha: 0.85),
                VoiceRoomTokens.neonPurple.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPink),
          ),
          child: Text(
            event.senderName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(emoji, style: const TextStyle(fontSize: 36))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.08, 1.08),
              duration: 400.ms,
            ),
        if (event.combo > 1)
          Text(
            'x${event.combo}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppThemeColors.coinGold,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  String _emojiFor(LiveGiftEvent e) =>
      PremiumGiftCatalog2026.emoji(e.giftId);
}

class _FlightItem {
  _FlightItem({
    required this.event,
    required this.controller,
    required this.startX,
    required this.wobble,
  });

  final LiveGiftEvent event;
  final AnimationController controller;
  final double startX;
  final double wobble;
}

class _AmbientParticle {
  _AmbientParticle({required this.id, required this.emoji, required this.x});
  final int id;
  final String emoji;
  final double x;
}

class _AmbientWidget extends StatefulWidget {
  const _AmbientWidget({
    required this.particle,
    required this.height,
    required this.width,
  });

  final _AmbientParticle particle;
  final double height;
  final double width;

  @override
  State<_AmbientWidget> createState() => _AmbientWidgetState();
}

class _AmbientWidgetState extends State<_AmbientWidget> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.width * widget.particle.x,
      bottom: widget.height * 0.1,
      child: Text(widget.particle.emoji, style: const TextStyle(fontSize: 16))
          .animate()
          .moveY(begin: 0, end: -widget.height * 0.55, duration: 3.2.seconds)
          .fadeOut(duration: 2.8.seconds),
    );
  }
}
