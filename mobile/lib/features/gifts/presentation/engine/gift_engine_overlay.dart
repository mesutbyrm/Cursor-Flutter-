import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';
import '../../domain/gift_media_spec.dart';
import '../../domain/gift_media_type.dart';
import '../widgets/gift_animation_player.dart';
import '../widgets/gift_media_widget.dart';
import '../widgets/gift_stage_layout.dart';

/// Backend Gift Engine — tek aktif animasyon, alan ve öncelik backend'den.
class GiftEngineOverlay extends ConsumerStatefulWidget {
  const GiftEngineOverlay({
    super.key,
    required this.event,
    required this.stage,
    this.enabled = true,
    this.onFinished,
    this.seatIndex,
  });

  final LiveGiftEvent? event;
  final GiftStageContext stage;
  final bool enabled;
  final ValueChanged<String>? onFinished;
  final int? seatIndex;

  @override
  ConsumerState<GiftEngineOverlay> createState() => _GiftEngineOverlayState();
}

class _GiftEngineOverlayState extends ConsumerState<GiftEngineOverlay> {
  Timer? _finishTimer;
  var _visible = false;

  @override
  void didUpdateWidget(covariant GiftEngineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event?.id != widget.event?.id) {
      _schedule();
    }
  }

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _finishTimer?.cancel();
    _visible = false;
    final ev = widget.event;
    if (!widget.enabled || ev == null) return;

    final config = GiftEngineParser.fromEvent(ev);
    final delay = Duration(milliseconds: config.startDelayMs);
    final duration = Duration(milliseconds: config.durationMs);

    Future<void>.delayed(delay, () {
      if (!mounted || widget.event?.id != ev.id) return;
      setState(() => _visible = true);
      _finishTimer = Timer(duration, () {
        if (!mounted) return;
        widget.onFinished?.call(ev.id);
      });
    });
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    if (!widget.enabled || ev == null || !_visible) {
      return const SizedBox.shrink();
    }

    final config = GiftEngineParser.fromEvent(ev);
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    final giftSize = config.priority.sizeFactor(shortest);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            _positionedAnimation(
              context: context,
              config: config,
              event: ev,
              giftSize: giftSize,
              seatIndex: widget.seatIndex ?? ev.seatIndex,
            ),
            if (config.showComboBadge)
              _ComboBadge(
                combo: config.combo,
                displayArea: config.displayArea,
              ),
          ],
        ),
      ),
    );
  }

  Widget _positionedAnimation({
    required BuildContext context,
    required GiftEngineConfig config,
    required LiveGiftEvent event,
    required double giftSize,
    int? seatIndex,
  }) {
    final child = _GiftEngineAnimation(
      event: event,
      config: config,
      size: giftSize,
    );

    return switch (config.displayArea) {
      GiftEngineDisplayArea.fullScreen => Positioned.fill(child: child),
      GiftEngineDisplayArea.center => GiftStageBand(
          stage: widget.stage,
          child: Center(child: child),
        ),
      GiftEngineDisplayArea.top => GiftStageBand(
          stage: widget.stage,
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      GiftEngineDisplayArea.bottom => GiftStageBand(
          stage: widget.stage,
          child: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      GiftEngineDisplayArea.seat => _seatPositioned(context, seatIndex, child),
    };
  }

  Widget _seatPositioned(BuildContext context, int? seatIndex, Widget child) {
    final idx = seatIndex ?? 0;
    final w = MediaQuery.sizeOf(context).width;
    const cols = 4;
    final col = idx % cols;
    final row = idx ~/ cols;
    final left = 16 + col * (w - 32) / cols;
    final top = 120.0 + row * 88;
    return Positioned(
      left: left,
      top: top,
      width: 72,
      height: 72,
      child: child,
    );
  }
}

class _GiftEngineAnimation extends StatelessWidget {
  const _GiftEngineAnimation({
    required this.event,
    required this.config,
    required this.size,
  });

  final LiveGiftEvent event;
  final GiftEngineConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = event.giftIcon ?? '🎁';

    if (config.animationType == GiftEngineAnimationType.particle) {
      return FloatingGiftParticles(
        emojis: [emoji],
        spawnFromGiftId: event.giftId,
      );
    }

    if (config.animationType == GiftEngineAnimationType.lottie ||
        config.animationType == GiftEngineAnimationType.rive ||
        config.animationType == GiftEngineAnimationType.svga) {
      return GiftAnimationPlayer(
        giftId: event.giftId,
        event: event,
        size: size,
        preferPremiumVisual: false,
        fit: BoxFit.contain,
      );
    }

    final spec = GiftMediaSpec.fromEvent(event, engine: config);
    if (spec.mediaType == GiftMediaType.unknown &&
        !spec.hasPlayableUrl &&
        spec.thumbnailUrl == null) {
      return GiftAnimationPlayer(
        giftId: event.giftId,
        event: event,
        size: size,
        preferPremiumVisual: false,
      );
    }

    final fit = config.isFullScreen ||
            config.displayArea == GiftEngineDisplayArea.fullScreen
        ? BoxFit.cover
        : BoxFit.contain;

    return GiftMediaWidget(
      spec: spec,
      width: size,
      height: size,
      fit: fit,
      fallbackEmoji: emoji,
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({
    required this.combo,
    required this.displayArea,
  });

  final int combo;
  final GiftEngineDisplayArea displayArea;

  @override
  Widget build(BuildContext context) {
    final label = switch (combo) {
      >= 100 => 'x100',
      >= 10 => 'x10',
      >= 5 => 'x5',
      >= 2 => 'x2',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();

    final top = displayArea == GiftEngineDisplayArea.fullScreen ? 80.0 : 48.0;
    return Positioned(
      top: top,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF6E40)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}
