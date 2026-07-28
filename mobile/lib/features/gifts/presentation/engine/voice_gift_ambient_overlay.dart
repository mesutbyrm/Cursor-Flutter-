import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../../data/gift_cache_service.dart';
import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';
import '../sync/gift_session_controller.dart';
import '../widgets/gift_animation_player.dart';
import '../../../voice_hub/presentation/providers/voice_room_ui_provider.dart';

/// Sesli oda hediye katmanı — arka plan üstünde, UI altında.
/// %40 opaklık, üst fade, yumuşak fade-out; etkileşimi engellemez.
class VoiceGiftAmbientOverlay extends ConsumerStatefulWidget {
  const VoiceGiftAmbientOverlay({
    super.key,
    required this.sessionKey,
  });

  final String sessionKey;

  static const ambientOpacity = 0.4;
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
  VideoPlayerController? _video;

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
      _disposeVideo();
      ref.read(giftSessionProvider(widget.sessionKey).notifier).dequeueAnimation(id);
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _fadeCtrl.removeStatusListener(_onFadeStatus);
    _fadeCtrl.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    final c = _video;
    _video = null;
    c?.dispose();
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
    _disposeVideo();
    _activeId = ev.id;

    final config = GiftEngineParser.fromEvent(ev);
    unawaited(_prepareMedia(ev, config));

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

  Future<void> _prepareMedia(LiveGiftEvent ev, GiftEngineConfig config) async {
    final type = config.animationType;
    if (type != GiftEngineAnimationType.mp4 &&
        type != GiftEngineAnimationType.webm) {
      return;
    }
    final url = config.videoUrl ?? config.resolvedAssetUrl;
    if (url == null || !url.startsWith('http')) return;
    try {
      await GiftCacheService.instance.getBytes(url);
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      if (!mounted || _activeId != ev.id) {
        await c.dispose();
        return;
      }
      c.setLooping(false);
      await c.play();
      setState(() {
        _disposeVideo();
        _video = c;
      });
    } catch (_) {}
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

    return IgnorePointer(
      child: RepaintBoundary(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut),
          child: Opacity(
            opacity: VoiceGiftAmbientOverlay.ambientOpacity,
            child: _AmbientMask(
              child: _AmbientContent(
                event: event,
                config: config,
                video: _video,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Üst/alt yumuşak geçiş — sert siyah çizgiyi kaldırır.
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
        stops: [0.0, 0.14, 0.82, 1.0],
      ).createShader(bounds),
      child: child,
    );
  }
}

class _AmbientContent extends StatelessWidget {
  const _AmbientContent({
    required this.event,
    required this.config,
    required this.video,
  });

  final LiveGiftEvent event;
  final GiftEngineConfig config;
  final VideoPlayerController? video;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
          final sizeFactor = switch (config.displayArea) {
            GiftEngineDisplayArea.seat => 0.28,
            GiftEngineDisplayArea.top || GiftEngineDisplayArea.bottom => 0.45,
            _ => 1.0,
          };
          final child = _buildMedia(w * sizeFactor, h * sizeFactor);

          return switch (config.displayArea) {
            GiftEngineDisplayArea.top => Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: w, height: h * 0.5, child: child),
              ),
            GiftEngineDisplayArea.bottom => Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(width: w, height: h * 0.45, child: child),
              ),
            GiftEngineDisplayArea.seat => _seatAligned(context, child),
            _ => SizedBox(width: w, height: h, child: child),
          };
        },
      );
  }

  Widget _seatAligned(BuildContext context, Widget child) {
    final idx = event.seatIndex ?? 0;
    final w = MediaQuery.sizeOf(context).width;
    final cols = 4;
    final col = idx % cols;
    final row = idx ~/ cols;
    return Stack(
      children: [
        Positioned(
          left: 8 + col * (w - 16) / cols,
          top: 100 + row * 84,
          width: 88,
          height: 88,
          child: child,
        ),
      ],
    );
  }

  Widget _buildMedia(double w, double h) {
    final url = config.resolvedAssetUrl;
    final emoji = event.giftIcon ?? '🎁';

    return switch (config.animationType) {
      GiftEngineAnimationType.mp4 || GiftEngineAnimationType.webm => () {
          final c = video;
          if (c != null && c.value.isInitialized) {
            return ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            );
          }
          final thumb = config.thumbnailUrl ?? event.displayImageUrl;
          if (thumb != null && thumb.isNotEmpty) {
            return CanlifalNetworkImage(
              url: thumb,
              width: w,
              height: h,
              fit: BoxFit.cover,
            );
          }
          return const SizedBox.shrink();
        }(),
      GiftEngineAnimationType.lottie when url != null && url.isNotEmpty =>
        Lottie.network(
          url,
          width: w,
          height: h,
          fit: BoxFit.cover,
          repeat: false,
        ),
      GiftEngineAnimationType.svg when url != null && url.isNotEmpty =>
        SvgPicture.network(
          url,
          width: w,
          height: h,
          fit: BoxFit.cover,
        ),
      GiftEngineAnimationType.png ||
      GiftEngineAnimationType.gif =>
        CanlifalNetworkImage(
          url: url ?? event.displayImageUrl ?? '',
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorWidget: _fallback(emoji, h),
        ),
      GiftEngineAnimationType.particle => FloatingGiftParticles(
          emojis: [emoji],
          spawnFromGiftId: event.giftId,
        ),
      _ => GiftAnimationPlayer(
          giftId: event.giftId,
          event: event,
          size: h,
          preferPremiumVisual: false,
          fit: BoxFit.cover,
        ),
    };
  }

  Widget _fallback(String emoji, double h) =>
      Center(child: Text(emoji, style: TextStyle(fontSize: h * 0.2)));
}
