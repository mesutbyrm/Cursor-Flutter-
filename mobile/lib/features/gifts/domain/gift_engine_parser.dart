import '../../live/domain/entities/live_gift_event.dart';
import 'gift_engine_models.dart';
import 'gift_media_spec.dart';

/// Backend giftRender / giftEngine JSON → [GiftEngineConfig].
/// Jeton fiyatına göre hesaplama yapılmaz; yalnızca sunucu alanları okunur.
abstract final class GiftEngineParser {
  static GiftEngineConfig fromEvent(LiveGiftEvent event) {
    return fromMaps(
      event: event,
      render: _renderMap(event),
    );
  }

  static Map<String, dynamic> _renderMap(LiveGiftEvent event) {
    // LiveGiftEvent alanları zaten giftRender'dan parse edilmiş olabilir.
    return {
      'priority': event.enginePriority,
      'displayArea': event.engineDisplayArea,
      'animationType': event.engineAnimationType,
      'durationMs': event.engineDurationMs,
      'queueGapMs': event.engineQueueGapMs,
      'feedDurationMs': event.engineFeedDurationMs,
      'startDelayMs': event.startDelayMs,
      'combo': event.combo,
      'seatEffects': event.engineSeatEffects,
      'assetUrl': event.assetUrl ?? event.animationKey,
      'imageUrl': event.imageUrl,
      'videoUrl': event.videoUrl,
      'thumbnailUrl': event.thumbnailUrl,
      'effectColor': event.effectColor,
      'particleKey': event.engineParticleKey,
      'screenPosition': event.screenPosition,
      'tier': event.tier,
      'isFullscreen': event.isFullscreen,
      'displayType': event.displayType,
      'displayDurationMs': event.displayDurationMs,
      'animationDurationMs': event.animationDurationMs,
      'assetFormat': event.assetFormat,
      'assetType': event.assetType,
      'mediaType': event.mediaType,
      'width': event.mediaWidth,
      'height': event.mediaHeight,
      'mediaWidth': event.mediaWidth,
      'mediaHeight': event.mediaHeight,
    };
  }

  static GiftEngineConfig fromJson(Map<String, dynamic> json) {
    return fromMaps(render: json);
  }

  static GiftEngineConfig fromMaps({
    LiveGiftEvent? event,
    required Map<String, dynamic> render,
  }) {
    final priorityRaw = _pick(render, [
      'priority',
      'giftPriority',
      'animationPriority',
    ]);
    final displayRaw = _pick(render, [
      'displayArea',
      'display_area',
      'screenPosition',
      'screen_position',
    ]);
    final animTypeRaw = _pick(render, [
      'animationType',
      'animation_type',
      'assetFormat',
      'asset_format',
      'assetType',
      'asset_type',
      'animationKind',
    ]);

    var priority = GiftEnginePriority.parse(priorityRaw);
    var displayArea = GiftEngineDisplayArea.parse(displayRaw);

    // Yalnızca backend bayrakları — fiyat hesabı yok.
    final tier = render['tier']?.toString();
    if (priorityRaw == null && tier != null) {
      priority = GiftEnginePriority.parse(tier);
    }
    if (render['isFullscreen'] == true ||
        render['displayType']?.toString().toLowerCase() == 'fullscreen') {
      displayArea = GiftEngineDisplayArea.fullScreen;
      if (priority == GiftEnginePriority.medium) {
        priority = GiftEnginePriority.ultra;
      }
    }

    final animType = GiftEngineAnimationType.parse(animTypeRaw);
    final assetUrl = _pick(render, ['assetUrl', 'animationUrl', 'animation']);
    final videoUrlRaw = _pick(render, ['videoUrl', 'video_url']);
    final videoUrl = videoUrlRaw ??
        (GiftEngineAnimationType.inferFromUrl(assetUrl) ==
                    GiftEngineAnimationType.mp4 ||
                GiftEngineAnimationType.inferFromUrl(assetUrl) ==
                    GiftEngineAnimationType.webm
            ? assetUrl
            : null);

    var resolvedAnim = animType == GiftEngineAnimationType.none
        ? GiftEngineAnimationType.parse(event?.assetFormat ?? event?.assetType)
        : animType;
    if (resolvedAnim == GiftEngineAnimationType.none) {
      resolvedAnim = GiftEngineAnimationType.inferFromUrl(videoUrl ?? assetUrl);
    }
    final assetType = event?.assetType?.toLowerCase().trim();
    if (assetType == 'video' &&
        (resolvedAnim == GiftEngineAnimationType.none ||
            resolvedAnim == GiftEngineAnimationType.png)) {
      resolvedAnim = GiftEngineAnimationType.inferFromUrl(videoUrl ?? assetUrl);
      if (resolvedAnim == GiftEngineAnimationType.none) {
        resolvedAnim = GiftEngineAnimationType.mp4;
      }
    }

    final isVideoAnim = resolvedAnim == GiftEngineAnimationType.mp4 ||
        resolvedAnim == GiftEngineAnimationType.webm;
    if (isVideoAnim &&
        displayArea == GiftEngineDisplayArea.center &&
        displayRaw == null) {
      displayArea = GiftEngineDisplayArea.fullScreen;
      if (priority == GiftEnginePriority.medium) {
        priority = GiftEnginePriority.large;
      }
    }

    var durationMs = _int(render, [
          'durationMs',
          'duration_ms',
          'displayDurationMs',
          'display_duration_ms',
          'animationDurationMs',
          'animation_duration_ms',
        ]) ??
        3000;
    if (isVideoAnim && durationMs <= 3000) {
      durationMs = 8000;
    }

    final queueGapMs =
        _int(render, ['queueGapMs', 'queue_gap_ms', 'gapMs', 'gap_ms']) ?? 300;

    final feedDurationMs = _int(render, [
          'feedDurationMs',
          'feed_duration_ms',
          'feedTtlMs',
        ]) ??
        3000;

    final startDelayMs =
        _int(render, ['startDelayMs', 'start_delay_ms']) ?? 0;

    final combo = _int(render, ['combo', 'comboCount']) ??
        event?.combo ??
        1;

    final seatEffects = _parseSeatEffects(render['seatEffects'] ??
        render['seat_effects'] ??
        render['seatEffect']);

    return GiftEngineConfig(
      priority: priority,
      displayArea: displayArea,
      animationType: resolvedAnim,
      durationMs: durationMs.clamp(500, 30000),
      queueGapMs: queueGapMs.clamp(0, 5000),
      feedDurationMs: feedDurationMs.clamp(1000, 15000),
      startDelayMs: startDelayMs.clamp(0, 10000),
      combo: combo.clamp(1, 9999),
      seatEffects: seatEffects,
      assetUrl: assetUrl,
      imageUrl: _pick(render, ['imageUrl', 'image_url', 'iconUrl', 'icon']),
      videoUrl: videoUrl,
      thumbnailUrl: _pick(render, ['thumbnailUrl', 'thumbnail_url']),
      effectColor: _pick(render, ['effectColor', 'effect_color']),
      particleKey: _pick(render, ['particleKey', 'particle_key', 'particleEffect', 'animation']),
      mediaType: GiftMediaSpec.parseMediaType(render),
      assetFormat: _pick(render, ['assetFormat', 'asset_format']),
      mediaWidth: GiftMediaSpec.parseDimensions(render).$1,
      mediaHeight: GiftMediaSpec.parseDimensions(render).$2,
    );
  }

  static List<GiftSeatEffect> _parseSeatEffects(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => GiftSeatEffect.parse(e?.toString()))
          .whereType<GiftSeatEffect>()
          .toList();
    }
    final single = GiftSeatEffect.parse(raw?.toString());
    if (single != null) return [single];
    return const [];
  }

  static String? _pick(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static int? _int(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      if (v is int) return v;
      final p = int.tryParse(v.toString());
      if (p != null) return p;
    }
    return null;
  }
}
