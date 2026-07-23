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
  });

  factory GiftEntity.fromJson(Map<String, dynamic> json, {String siteOrigin = ''}) {
    final id = pick(json, ['id', 'slug', 'giftTypeId'])?.toString() ?? '';
    final rawIcon = pick(json, ['icon'])?.toString();
    final iconUrlField = pick(json, ['iconUrl'])?.toString();
    final thumbnail = pick(json, ['thumbnailUrl'])?.toString();
    final asset = pick(json, ['assetUrl', 'image', 'giftImageUrl'])?.toString();
    final anim = pick(json, ['animation', 'animationKey'])?.toString();
    final animType = GiftAnimationKind.parse(
      pick(json, ['animationType', 'animationKind', 'assetType'])?.toString(),
    );

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

    return GiftEntity(
      id: id,
      name: (pick(json, ['name', 'nameTr', 'nameEn']) ?? id).toString(),
      price: asInt(pick(json, ['price'])),
      iconUrl: imageUrl,
      animationRef: anim ?? resolvedAsset,
      animationKind: animType,
      rarity: GiftRarity.parse(pick(json, ['rarity'])?.toString()),
      platform: GiftPlatform.parse(pick(json, ['platform'])?.toString()),
      soundKey: pick(json, ['sound'])?.toString(),
      sortOrder: asInt(pick(json, ['sortOrder'])),
      isLucky: json['isLucky'] == true,
      collectionId: pick(json, ['collectionId'])?.toString(),
      thumbnailUrl: _isResolvableUrl(thumbnail ?? '')
          ? _resolveUrl(thumbnail, siteOrigin)
          : null,
      assetUrl: resolvedAsset,
      iconEmoji: emoji,
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

  /// Görüntüleme için en iyi ikon URL'si (thumbnail öncelikli).
  String? get displayIconUrl => thumbnailUrl ?? iconUrl ?? assetUrl;

  bool get hasFullscreenAnimation =>
      animationKind != GiftAnimationKind.none &&
      (animationRef?.isNotEmpty ?? false);

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
