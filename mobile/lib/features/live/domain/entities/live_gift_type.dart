import '../../../gifts/domain/gift_animation_kind.dart';
import '../../../gifts/domain/gift_entity.dart';
import '../../../gifts/domain/gift_platform.dart';
import '../../../gifts/domain/gift_rarity.dart';

/// `/api/video-streams/gifts` satırı (site ile aynı hediye türleri).
class LiveVideoGiftType {
  LiveVideoGiftType({
    required this.id,
    required this.name,
    required this.price,
    this.iconPath,
    this.rarity = GiftRarity.common,
    this.animationKind = GiftAnimationKind.lottie,
    this.animationRef,
    this.soundKey,
    this.platform = GiftPlatform.all,
  });

  factory LiveVideoGiftType.fromJson(Map<String, dynamic> json) {
    return LiveVideoGiftType.fromGift(GiftEntity.fromJson(json));
  }

  factory LiveVideoGiftType.fromGift(GiftEntity g) {
    return LiveVideoGiftType(
      id: g.id,
      name: g.name,
      price: g.price,
      iconPath: g.iconUrl,
      rarity: g.rarity,
      animationKind: g.animationKind,
      animationRef: g.animationRef,
      soundKey: g.soundKey,
      platform: g.platform,
    );
  }

  final String id;
  final String name;
  final int price;
  final String? iconPath;
  final GiftRarity rarity;
  final GiftAnimationKind animationKind;
  final String? animationRef;
  final String? soundKey;
  final GiftPlatform platform;

  GiftEntity toEntity() => GiftEntity(
        id: id,
        name: name,
        price: price,
        iconUrl: iconPath,
        rarity: rarity,
        animationKind: animationKind,
        animationRef: animationRef,
        soundKey: soundKey,
        platform: platform,
      );

  String iconUrl(String siteOrigin) {
    final p = iconPath;
    if (p == null || p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    final o = siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');
    return p.startsWith('/') ? '$o$p' : '$o/$p';
  }
}
