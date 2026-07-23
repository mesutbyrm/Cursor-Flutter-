import '../domain/gift_animation_kind.dart';
import '../domain/gift_entity.dart';

/// Yerel animasyon / emoji eşlemesi (API `animation: lottie:rose` vb.).
abstract final class GiftCatalogMaps {
  static const lottieAssetByKey = <String, String>{
    'lottie:rose': 'assets/gifts/lottie/rose.json',
    'lottie:heart': 'assets/gifts/lottie/heart.json',
    'lottie:star': 'assets/gifts/lottie/star.json',
    'lottie:crown': 'assets/gifts/lottie/crown.json',
    'lottie:car': 'assets/gifts/lottie/car.json',
    'lottie:yacht': 'assets/gifts/lottie/star.json',
    'rose': 'assets/gifts/lottie/rose.json',
    'heart': 'assets/gifts/lottie/heart.json',
    'star': 'assets/gifts/lottie/star.json',
    'crown': 'assets/gifts/lottie/crown.json',
    'car': 'assets/gifts/lottie/car.json',
    'yacht': 'assets/gifts/lottie/star.json',
    'gul': 'assets/gifts/lottie/rose.json',
    'kalp': 'assets/gifts/lottie/heart.json',
    'yildiz': 'assets/gifts/lottie/star.json',
    'tac': 'assets/gifts/lottie/crown.json',
    'araba': 'assets/gifts/lottie/car.json',
    'yat': 'assets/gifts/lottie/star.json',
  };

  static const svgaAssetByKey = <String, String>{
    'svga:galaxy': 'assets/gifts/svga/galaxy.svga',
    'galaxy': 'assets/gifts/svga/galaxy.svga',
    'galaksi': 'assets/gifts/svga/galaxy.svga',
  };

  static const emojiById = <String, String>{
    'gul': '🌹',
    'kalp': '💖',
    'yildiz': '⭐',
    'tac': '👑',
    'roket': '🚀',
    'elmas': '💎',
    'galaksi': '🌌',
    'aslan': '🦁',
    'araba': '🏎️',
    'yat': '🛥️',
    'rocket': '🚀',
    'galaxy': '🌌',
    'lion': '🦁',
    'diamond': '💎',
    'heart': '💖',
    'crown': '👑',
    'yacht': '🛥️',
  };

  /// CMS animasyonu varsa premium painter kullanma.
  static bool usePremiumPainter(GiftEntity gift) {
    if (gift.hasCmsAnimation) return false;
    final id = gift.id.toLowerCase();
    return id == 'galaksi' ||
        id == 'aslan' ||
        id == 'yat' ||
        id == 'roket' ||
        id == 'rocket' ||
        id == 'elmas' ||
        id == 'diamond' ||
        id == 'kristal';
  }

  static String? lottieAsset(GiftEntity gift) {
    final ref = gift.animationRef;
    if (ref != null && ref.startsWith('http')) return null;
    if (ref == null) return lottieAssetByKey[gift.id];
    return lottieAssetByKey[ref] ?? lottieAssetByKey[gift.id];
  }

  static String? svgaAsset(GiftEntity gift) {
    final ref = gift.animationRef;
    if (ref != null && ref.startsWith('http')) return null;
    if (ref == null) return svgaAssetByKey[gift.id];
    return svgaAssetByKey[ref] ?? svgaAssetByKey[gift.id];
  }

  static String emoji(GiftEntity gift) =>
      gift.iconEmoji ??
      emojiById[gift.id] ??
      emojiById[gift.animationRef ?? ''] ??
      '🎁';

  static GiftAnimationKind resolvedKind(GiftEntity gift) {
    if (gift.animationKind != GiftAnimationKind.lottie &&
        gift.animationKind != GiftAnimationKind.none) {
      return gift.animationKind;
    }
    final network = gift.networkAnimationUrl;
    if (network != null) {
      final fromUrl = GiftAnimationKind.fromUrl(network);
      if (fromUrl != GiftAnimationKind.none) return fromUrl;
    }
    if (svgaAsset(gift) != null) return GiftAnimationKind.svga;
    if (lottieAsset(gift) != null) return GiftAnimationKind.lottie;
    if (network != null) return GiftAnimationKind.image;
    return GiftAnimationKind.none;
  }
}
