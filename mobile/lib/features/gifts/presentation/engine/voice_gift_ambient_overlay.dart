import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_media_spec.dart';
import '../../domain/gift_media_type.dart';
import '../providers/gift_catalog_index_provider.dart';
import '../sync/gift_session_controller.dart';
import '../widgets/gift_animation_player.dart';
import '../widgets/gift_media_widget.dart';
import '../../../voice_hub/presentation/providers/voice_room_ui_provider.dart';

/// Sesli oda hediye katmanı — arka plan üstünde, koltuk/chat altında tam ekran.
class VoiceGiftAmbientOverlay extends ConsumerStatefulWidget {
  const VoiceGiftAmbientOverlay({
    super.key,
    required this.sessionKey,
  });

  final String sessionKey;

  static const fadeInMs = 320;
  static const fadeOutMs = 480;

  @override
  ConsumerState<VoiceGiftAmbientOverlay> createState() =>
      _VoiceGiftAmbientOverlayState();
}

class _VoiceGiftAmbientOverlayState extends ConsumerState<VoiceGiftAmbientOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  Timer? _playTimer;
  String? _activeId;
  String? _boundId;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: VoiceGiftAmbientOverlay.fadeInMs),
    );
    _fadeCtrl.addStatusListener(_onFadeStatus);
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _activeId != null) {
      final id = _activeId!;
      _activeId = null;
      ref.read(giftSessionProvider(widget.sessionKey).notifier).dequeueAnimation(id);
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _fadeCtrl.removeStatusListener(_onFadeStatus);
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _bindEvent(LiveGiftEvent? ev, bool enabled) {
    if (!enabled || ev == null) {
      _playTimer?.cancel();
      if (_fadeCtrl.value > 0) {
        _fadeCtrl.duration =
            const Duration(milliseconds: VoiceGiftAmbientOverlay.fadeOutMs);
        _fadeCtrl.reverse();
      }
      return;
    }
    if (_activeId == ev.id) return;

    _playTimer?.cancel();
    _activeId = ev.id;

    final config = GiftEngineParser.fromEvent(ev);
    Future<void>.delayed(Duration(milliseconds: config.startDelayMs), () {
      if (!mounted || _activeId != ev.id) return;
      _fadeCtrl.duration =
          const Duration(milliseconds: VoiceGiftAmbientOverlay.fadeInMs);
      _fadeCtrl.forward(from: 0);

      _playTimer = Timer(Duration(milliseconds: config.durationMs), () {
        if (!mounted || _activeId != ev.id) return;
        _fadeCtrl.duration =
            const Duration(milliseconds: VoiceGiftAmbientOverlay.fadeOutMs);
        _fadeCtrl.reverse();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      voiceRoomUiProvider.select((s) => s.giftAnimationsEnabled),
    );
    final event = ref.watch(
      giftSessionProvider(widget.sessionKey).select((s) => s.activeAnimation),
    );

    final eventId = event?.id;
    if (eventId != _boundId) {
      _boundId = eventId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bindEvent(event, enabled);
      });
    } else if (!enabled && _fadeCtrl.value > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bindEvent(null, false);
      });
    }

    final show = enabled &&
        event != null &&
        (_activeId == event.id || _fadeCtrl.value > 0);
    if (!show) {
      return const SizedBox.shrink();
    }

    final config = GiftEngineParser.fromEvent(event);
    final catalog = lookupGiftCatalog(
      ref.watch(giftCatalogByIdProvider),
      event.giftId,
    );
    final isFullScreen = config.isFullScreen ||
        config.displayArea == GiftEngineDisplayArea.fullScreen;
    final isVideo = config.animationType == GiftEngineAnimationType.mp4 ||
        config.animationType == GiftEngineAnimationType.webm;
    final layerOpacity = isFullScreen || isVideo ? 1.0 : 0.88;

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut),
            child: Opacity(
              opacity: layerOpacity,
              child: isFullScreen
                  ? _AmbientContent(
                      event: event,
                      config: config,
                      catalog: catalog,
                    )
                  : _AmbientMask(
                      child: _AmbientContent(
                        event: event,
                        config: config,
                        catalog: catalog,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientMask extends StatelessWidget {
  const _AmbientMask({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.1, 0.88, 1.0],
      ).createShader(bounds),
      child: child,
    );
  }
}

class _AmbientContent extends StatelessWidget {
  const _AmbientContent({
    required this.event,
    required this.config,
    required this.catalog,
  });

  final LiveGiftEvent event;
  final GiftEngineConfig config;
  final GiftEntity? catalog;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final isFull = config.isFullScreen ||
            config.displayArea == GiftEngineDisplayArea.fullScreen;
        final sizeFactor = switch (config.displayArea) {
          GiftEngineDisplayArea.seat => 0.32,
          GiftEngineDisplayArea.top || GiftEngineDisplayArea.bottom => 0.5,
          GiftEngineDisplayArea.fullScreen => 1.0,
          _ => isFull ? 1.0 : 0.72,
        };
        final child = _buildMedia(
          w * sizeFactor,
          h * sizeFactor,
          catalog,
        );

        return switch (config.displayArea) {
          GiftEngineDisplayArea.top => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: w, height: h * 0.55, child: child),
            ),
          GiftEngineDisplayArea.bottom => Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(width: w, height: h * 0.5, child: child),
            ),
          GiftEngineDisplayArea.seat => _seatAligned(context, child),
          GiftEngineDisplayArea.fullScreen => SizedBox(width: w, height: h, child: child),
          _ => Center(
              child: SizedBox(
                width: w,
                height: h * (isFull ? 1.0 : 0.78),
                child: child,
              ),
            ),
        };
      },
    );
  }

  Widget _seatAligned(BuildContext context, Widget child) {
    final idx = event.seatIndex ?? 0;
    final w = MediaQuery.sizeOf(context).width;
    const cols = 4;
    final col = idx % cols;
    final row = idx ~/ cols;
    return Stack(
      children: [
        Positioned(
          left: 8 + col * (w - 16) / cols,
          top: 100 + row * 84,
          width: 96,
          height: 96,
          child: child,
        ),
      ],
    );
  }

  Widget _buildMedia(double w, double h, GiftEntity? catalog) {
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
        gift: catalog,
        size: h,
        preferPremiumVisual: false,
        fit: BoxFit.contain,
      );
    }

    final spec = GiftMediaSpec.fromEvent(event, catalog: catalog, engine: config);
    if (spec.mediaType == GiftMediaType.unknown &&
        !spec.hasPlayableUrl &&
        spec.thumbnailUrl == null) {
      return GiftAnimationPlayer(
        giftId: event.giftId,
        event: event,
        gift: catalog,
        size: h,
        preferPremiumVisual: false,
        fit: BoxFit.contain,
      );
    }

    final isFull = config.isFullScreen ||
        config.displayArea == GiftEngineDisplayArea.fullScreen;
    final fit = isFull || spec.mediaType.isVideo ? BoxFit.cover : BoxFit.contain;

    return GiftMediaWidget(
      spec: spec,
      width: w,
      height: h,
      fit: fit,
      fallbackEmoji: emoji,
    );
  }
}
