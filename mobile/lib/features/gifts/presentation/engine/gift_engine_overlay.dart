import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';
import '../../domain/gift_media_spec.dart';
import '../../domain/gift_media_type.dart';
import '../providers/gift_catalog_index_provider.dart';
import '../sync/gift_session_controller.dart';
import '../widgets/gift_animation_player.dart';
import '../widgets/gift_media_widget.dart';
import '../widgets/gift_stage_layout.dart';
import '../../../../core/design_system/cds_overlay_priority.dart';

/// Backend Gift Engine — tek aktif animasyon, alan ve öncelik backend'den.
class GiftEngineOverlay extends ConsumerStatefulWidget {
  const GiftEngineOverlay({
    super.key,
    required this.event,
    required this.stage,
    this.enabled = true,
    this.onFinished,
    this.seatIndex,
    this.sessionKey,
  });

  final LiveGiftEvent? event;
  final GiftStageContext stage;
  final bool enabled;
  final ValueChanged<String>? onFinished;
  final int? seatIndex;

  /// Hediye sesi için oturum anahtarı (canlı yayın / sesli oda).
  final String? sessionKey;

  @override
  ConsumerState<GiftEngineOverlay> createState() => _GiftEngineOverlayState();
}

class _GiftEngineOverlayState extends ConsumerState<GiftEngineOverlay> {
  Timer? _finishTimer;
  var _visible = false;
  String? _gateEventId;

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

  void _releaseGate() {
    final id = _gateEventId;
    if (id == null) return;
    CdsFullscreenGiftGate.instance.release(id);
    _gateEventId = null;
  }

  void _schedule() {
    _finishTimer?.cancel();
    _releaseGate();
    _visible = false;
    final ev = widget.event;
    if (!widget.enabled || ev == null) return;

    final config = GiftEngineParser.fromEvent(ev);
    final delay = Duration(milliseconds: config.startDelayMs);
    final duration = Duration(milliseconds: config.durationMs);

    Future<void>.delayed(delay, () {
      if (!mounted || widget.event?.id != ev.id) return;
      if (!CdsFullscreenGiftGate.instance.tryAcquire(ev.id)) {
        widget.onFinished?.call(ev.id);
        return;
      }
      _gateEventId = ev.id;
      setState(() => _visible = true);
      final key = widget.sessionKey?.trim();
      if (key != null && key.isNotEmpty) {
        ref.read(giftSessionProvider(key).notifier).playActiveGiftSound(ev);
      }
      _finishTimer = Timer(duration, () {
        if (!mounted) return;
        _releaseGate();
        widget.onFinished?.call(ev.id);
      });
    });
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _releaseGate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    if (!widget.enabled || ev == null || !_visible) {
      return const SizedBox.shrink();
    }

    final config = GiftEngineParser.fromEvent(ev);
    final catalog = ref.watch(giftCatalogByIdProvider);
    final giftMeta = lookupGiftCatalog(catalog, ev.giftId);
    final comboAllowed = giftMeta?.comboEnabled ?? true;
    final size = MediaQuery.sizeOf(context);
    final shortest = size.shortestSide;
    // Hediye asla tam ekran olmaz — boyut ekranın ~%48'i ile sınırlı.
    final giftSize = math.min(
      config.priority.sizeFactor(shortest),
      GiftStageMetrics.maxGiftHeight(context),
    );

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
            if (config.showComboBadge && comboAllowed)
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

    // Koltuk efektleri küçük ve konumlu — dokunmuyoruz.
    if (config.displayArea == GiftEngineDisplayArea.seat) {
      return _seatPositioned(context, seatIndex, child);
    }

    // Tüm diğer hediyeler (fullScreen dahil) alttan-hizalı banda alınır;
    // hiçbir hediye tam ekran açılmaz. Alttan yukarı yumuşak giriş.
    return GiftStageBand(
      stage: widget.stage,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: child
            .animate(key: ValueKey('gift-enter-${event.id}'))
            .fadeIn(duration: 220.ms)
            .slideY(begin: 0.28, end: 0, duration: 320.ms, curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 320.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
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

    // Hediye asla tam ekran değil: `size` ile sınırlı, kırpmasız `contain`.
    // (Eski `fullScreen`/`cover` yolu kaldırıldı; video da banda sığar.)
    return GiftMediaWidget(
      spec: spec,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fallbackEmoji: emoji,
      looping: false,
    );
  }
}

class _ComboBadge extends StatefulWidget {
  const _ComboBadge({
    required this.combo,
    required this.displayArea,
  });

  final int combo;
  final GiftEngineDisplayArea displayArea;

  @override
  State<_ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<_ComboBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic));
    if (widget.combo >= 2) {
      unawaited(_pulse.forward(from: 0));
    }
  }

  @override
  void didUpdateWidget(covariant _ComboBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.combo != widget.combo && widget.combo >= 2) {
      unawaited(_pulse.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 2) return const SizedBox.shrink();
    final label = 'x${widget.combo}';
    final top =
        widget.displayArea == GiftEngineDisplayArea.fullScreen ? 80.0 : 48.0;
    return Positioned(
      top: top,
      right: 24,
      child: ScaleTransition(
        scale: _scale,
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
      ),
    );
  }
}
