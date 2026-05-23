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
  });

  factory GiftEntity.fromJson(Map<String, dynamic> json, {String siteOrigin = ''}) {
    final id = pick(json, ['id', 'slug', 'giftTypeId'])?.toString() ?? '';
    final icon = pick(json, ['icon', 'iconUrl'])?.toString();
    final anim = pick(json, ['animation', 'animationKey'])?.toString();
    final animType = GiftAnimationKind.parse(
      pick(json, ['animationType', 'animationKind'])?.toString(),
    );

    return GiftEntity(
      id: id,
      name: (pick(json, ['name', 'nameTr', 'nameEn']) ?? id).toString(),
      price: asInt(pick(json, ['price'])),
      iconUrl: _resolveUrl(icon, siteOrigin),
      animationRef: anim,
      animationKind: animType,
      rarity: GiftRarity.parse(pick(json, ['rarity'])?.toString()),
      platform: GiftPlatform.parse(pick(json, ['platform'])?.toString()),
      soundKey: pick(json, ['sound'])?.toString(),
      sortOrder: asInt(pick(json, ['sortOrder'])),
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
      ];
}

String? _resolveUrl(String? path, String origin) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  final o = origin.trim().replaceAll(RegExp(r'/+$'), '');
  return path.startsWith('/') ? '$o$path' : '$o/$path';
}
