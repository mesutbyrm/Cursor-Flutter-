import '../../../core/media/cloud_media_url.dart';
import '../../../core/util/json_util.dart';
import '../../live/domain/entities/live_gift_event.dart';
import 'gift_animation_kind.dart';
import 'gift_asset_type.dart';
import 'gift_engine_models.dart';
import 'gift_entity.dart';
import 'gift_media_type.dart';

/// Backend hediye medya alanları — tek oynatıcı girdisi.
class GiftMediaSpec {
  const GiftMediaSpec({
    this.mediaUrl,
    this.thumbnailUrl,
    this.mediaType = GiftMediaType.unknown,
    this.mediaWidth,
    this.mediaHeight,
  });

  final String? mediaUrl;
  final String? thumbnailUrl;
  final GiftMediaType mediaType;
  final int? mediaWidth;
  final int? mediaHeight;

  bool get hasPlayableUrl => mediaUrl != null && mediaUrl!.trim().isNotEmpty;

  double? get aspectRatio {
    final w = mediaWidth;
    final h = mediaHeight;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  static GiftMediaSpec fromGiftEntity(GiftEntity gift) {
    final url = gift.resolvedMediaUrl;
    final thumb = gift.resolvedThumbnailUrl;
    return GiftMediaSpec(
      mediaUrl: url,
      thumbnailUrl: thumb,
      mediaType: GiftMediaType.resolve(
        mediaType: gift.mediaType,
        assetType: gift.assetType.name,
        assetFormat: gift.assetFormat,
        url: url,
        catalogAssetType: gift.assetType,
        animationKind: gift.animationKind,
      ),
      mediaWidth: gift.mediaWidth,
      mediaHeight: gift.mediaHeight,
    );
  }

  static GiftMediaSpec fromEvent(
    LiveGiftEvent event, {
    GiftEntity? catalog,
    GiftEngineConfig? engine,
  }) {
    final type = GiftMediaType.resolve(
      mediaType: event.mediaType,
      assetType: event.assetType,
      assetFormat: event.assetFormat ?? engine?.assetFormat,
      animationType: event.engineAnimationType ?? engine?.animationType.name,
      url: _primaryUrl(event, catalog, engine),
      catalogAssetType: catalog?.assetType,
      animationKind: event.animationKind,
    );

    final url = _resolveUrl(
      _primaryUrl(event, catalog, engine, preferVideo: type.isVideo),
    );
    final thumb = _resolveUrl(
      event.thumbnailUrl ??
          catalog?.resolvedThumbnailUrl ??
          event.displayImageUrl ??
          catalog?.displayIconUrl,
    );

    return GiftMediaSpec(
      mediaUrl: url,
      thumbnailUrl: thumb,
      mediaType: type,
      mediaWidth: event.mediaWidth ??
          catalog?.mediaWidth ??
          engine?.mediaWidth,
      mediaHeight: event.mediaHeight ??
          catalog?.mediaHeight ??
          engine?.mediaHeight,
    );
  }

  static String? _primaryUrl(
    LiveGiftEvent event,
    GiftEntity? catalog,
    GiftEngineConfig? engine, {
    bool preferVideo = false,
  }) {
    if (preferVideo) {
      return event.videoUrl ??
          engine?.videoUrl ??
          event.assetUrl ??
          engine?.resolvedAssetUrl ??
          catalog?.resolvedMediaUrl ??
          event.animationKey;
    }
    return event.videoUrl ??
        event.assetUrl ??
        engine?.videoUrl ??
        engine?.resolvedAssetUrl ??
        event.imageUrl ??
        engine?.imageUrl ??
        catalog?.resolvedMediaUrl ??
        event.animationKey;
  }

  static String? _resolveUrl(String? raw) => CloudMediaUrl.resolve(raw);

  static int? parseDimension(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      if (v is int && v > 0) return v;
      final p = int.tryParse(v.toString());
      if (p != null && p > 0) return p;
    }
    return null;
  }

  static String? parseMediaType(Map<String, dynamic> json) {
    return pick(json, [
      'mediaType',
      'media_type',
      'assetType',
      'asset_type',
      'animationType',
      'animation_type',
      'assetFormat',
      'asset_format',
    ])?.toString();
  }

  static (int?, int?) parseDimensions(Map<String, dynamic> json) {
    final w = parseDimension(json, [
      'mediaWidth',
      'media_width',
      'width',
      'videoWidth',
      'video_width',
    ]);
    final h = parseDimension(json, [
      'mediaHeight',
      'media_height',
      'height',
      'videoHeight',
      'video_height',
    ]);
    return (w, h);
  }
}
