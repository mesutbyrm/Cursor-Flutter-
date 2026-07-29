import '../../../core/media/cloud_media_url.dart';
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
    this.isLucky = false,
    this.iconEmoji,
  });

  factory LiveVideoGiftType.fromJson(Map<String, dynamic> json) {
    return LiveVideoGiftType.fromGift(GiftEntity.fromJson(json));
  }

  factory LiveVideoGiftType.fromGift(GiftEntity g) {
    return LiveVideoGiftType(
      id: g.id,
      name: g.name,
      price: g.price,
      iconPath: g.displayIconUrl ?? g.iconEmoji,
      rarity: g.rarity,
      animationKind: g.animationKind,
      animationRef: g.animationRef ?? g.assetUrl,
      soundKey: g.soundKey,
      platform: g.platform,
      isLucky: g.isLucky,
      iconEmoji: g.iconEmoji,
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
  final bool isLucky;
  final String? iconEmoji;

  String? get displayEmoji {
    if (iconEmoji != null && iconEmoji!.isNotEmpty) return iconEmoji;
    final p = iconPath;
    if (p != null && p.isNotEmpty && !p.startsWith('http') && !p.startsWith('/')) {
      return p;
    }
    return null;
  }

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
        isLucky: isLucky,
        iconEmoji: iconEmoji,
      );

  String iconUrl(String siteOrigin) {
    final p = iconPath;
    if (p == null || p.isEmpty) return '';
    if (displayEmoji != null) return '';
    return CloudMediaUrl.resolve(p, siteOrigin: siteOrigin) ?? '';
  }
}
