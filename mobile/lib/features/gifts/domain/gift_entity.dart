import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';
import 'gift_animation_kind.dart';
import 'gift_platform.dart';
import 'gift_rarity.dart';

/// Katalog satırı — `/api/gifts` veya `/api/video-streams/gifts`.
class GiftEntity extends Equatable {
  const GiftEntity({
    required this.id,
    required this.name,
    required this.price,
    this.iconUrl,
    this.animationRef,
    this.animationKind = GiftAnimationKind.lottie,
    this.rarity = GiftRarity.common,
    this.platform = GiftPlatform.all,
    this.soundKey,
    this.sortOrder = 0,
    this.isLucky = false,
    this.collectionId,
    this.thumbnailUrl,
    this.assetUrl,
    this.iconEmoji,
    this.soundUrl,
    this.animationDurationMs = 0,
    this.isFullscreen = false,
    this.isPremium = false,
    this.comboEnabled = false,
  });

  factory GiftEntity.fromJson(Map<String, dynamic> json, {String siteOrigin = ''}) {
    final id = pick(json, ['id', 'slug', 'giftTypeId'])?.toString() ?? '';
    final rawIcon = pick(json, ['icon'])?.toString();
    final iconUrlField = pick(json, ['iconUrl'])?.toString();
    final thumbnail = pick(json, ['thumbnailUrl'])?.toString();
    final asset = pick(json, ['assetUrl', 'image', 'giftImageUrl'])?.toString();
    final animKey = pick(json, ['animation', 'animationKey'])?.toString();
    final animUrlRaw = pick(json, ['animationUrl'])?.toString();
    final animTypeRaw = pick(json, [
      'animationType',
      'animationKind',
      'assetType',
    ])?.toString();
    var animType = GiftAnimationKind.parse(animTypeRaw);

    String? imageUrl;
    for (final candidate in [thumbnail, asset, iconUrlField, rawIcon]) {
      if (candidate == null || candidate.isEmpty) continue;
      if (_isResolvableUrl(candidate)) {
        imageUrl = _resolveUrl(candidate, siteOrigin);
        break;
      }
    }

    String? emoji;
    if (rawIcon != null &&
        rawIcon.isNotEmpty &&
        !_isResolvableUrl(rawIcon) &&
        imageUrl == null) {
      emoji = rawIcon;
    }

    final resolvedAsset = _isResolvableUrl(asset ?? '')
        ? _resolveUrl(asset, siteOrigin)
        : null;
    final resolvedAnimUrl = _isResolvableUrl(animUrlRaw ?? '')
        ? _resolveUrl(animUrlRaw, siteOrigin)
        : null;
    final animationRef = resolvedAnimUrl ??
        ((animKey != null && animKey.isNotEmpty) ? animKey : null) ??
        resolvedAsset;
    if (animType == GiftAnimationKind.lottie) {
      final inferred = GiftAnimationKind.fromUrl(animationRef);
      if (inferred != GiftAnimationKind.none) animType = inferred;
    }

    final soundRaw = pick(json, ['soundUrl', 'sound', 'soundCloudPath'])?.toString();
    final soundUrl = _isResolvableUrl(soundRaw ?? '')
        ? _resolveUrl(soundRaw, siteOrigin)
        : null;

    return GiftEntity(
      id: id,
      name: (pick(json, ['name', 'nameTr', 'nameEn']) ?? id).toString(),
      price: asInt(pick(json, ['price'])),
      iconUrl: imageUrl,
      animationRef: animationRef,
      animationKind: animType,
      rarity: GiftRarity.parse(
        pick(json, ['rarity', 'tier'])?.toString(),
      ),
      platform: GiftPlatform.parse(pick(json, ['platform'])?.toString()),
      soundKey: soundUrl == null ? soundRaw : null,
      soundUrl: soundUrl,
      sortOrder: asInt(pick(json, ['sortOrder'])),
      isLucky: json['isLucky'] == true,
      collectionId: pick(json, ['collectionId'])?.toString(),
      thumbnailUrl: _isResolvableUrl(thumbnail ?? '')
          ? _resolveUrl(thumbnail, siteOrigin)
          : null,
      assetUrl: resolvedAsset,
      iconEmoji: emoji,
      animationDurationMs:
          asInt(pick(json, ['animationDurationMs', 'animationDuration'])),
      isFullscreen: json['isFullscreen'] == true,
      isPremium: json['isPremium'] == true || json['premium'] == true,
      comboEnabled:
          json['comboEnabled'] == true || json['supportsCombo'] == true,
    );
  }

  final String id;
  final String name;
  final int price;
  final String? iconUrl;
  final String? animationRef;
  final GiftAnimationKind animationKind;
  final GiftRarity rarity;
  final GiftPlatform platform;
  final String? soundKey;
  final int sortOrder;
  final bool isLucky;
  final String? collectionId;
  final String? thumbnailUrl;
  final String? assetUrl;
  final String? iconEmoji;
  final String? soundUrl;
  final int animationDurationMs;
  final bool isFullscreen;
  final bool isPremium;
  final bool comboEnabled;

  /// Görüntüleme için en iyi ikon URL'si (thumbnail öncelikli).
  String? get displayIconUrl => thumbnailUrl ?? iconUrl ?? assetUrl;

  String? get networkAnimationUrl {
    final ref = animationRef ?? assetUrl;
    if (ref != null && ref.startsWith('http')) return ref;
    return null;
  }

  bool get hasCmsAnimation {
    final url = networkAnimationUrl;
    if (url == null) return false;
    return animationKind == GiftAnimationKind.video ||
        animationKind == GiftAnimationKind.gif ||
        animationKind == GiftAnimationKind.svga ||
        animationKind == GiftAnimationKind.lottie ||
        animationKind == GiftAnimationKind.image;
  }

  bool get shouldFullscreen =>
      isFullscreen || isPremium || hasCmsAnimation || price >= 100;

  bool get hasFullscreenAnimation => hasCmsAnimation;

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        iconUrl,
        animationRef,
        animationKind,
        rarity,
        platform,
        soundKey,
        sortOrder,
        isLucky,
        collectionId,
        thumbnailUrl,
        assetUrl,
        iconEmoji,
        soundUrl,
        animationDurationMs,
        isFullscreen,
        isPremium,
        comboEnabled,
      ];
}

bool _isResolvableUrl(String value) {
  final v = value.trim();
  if (v.isEmpty) return false;
  return v.startsWith('http') || v.startsWith('/');
}

String? _resolveUrl(String? path, String origin) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  final o = origin.trim().replaceAll(RegExp(r'/+$'), '');
  return path.startsWith('/') ? '$o$path' : '$o/$path';
}
