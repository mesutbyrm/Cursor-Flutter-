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
    'rose': 'assets/gifts/lottie/rose.json',
    'heart': 'assets/gifts/lottie/heart.json',
    'star': 'assets/gifts/lottie/star.json',
    'crown': 'assets/gifts/lottie/crown.json',
    'car': 'assets/gifts/lottie/car.json',
    'gul': 'assets/gifts/lottie/rose.json',
    'kalp': 'assets/gifts/lottie/heart.json',
    'yildiz': 'assets/gifts/lottie/star.json',
    'tac': 'assets/gifts/lottie/crown.json',
    'roket': 'assets/gifts/lottie/car.json',
  };

  static const riveAssetByKey = <String, String>{
    'rive:diamond': 'assets/gifts/rive/diamond.riv',
    'diamond': 'assets/gifts/rive/diamond.riv',
    'elmas': 'assets/gifts/rive/diamond.riv',
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
  };

  static String? lottieAsset(GiftEntity gift) {
    final ref = gift.animationRef;
    if (ref == null) return lottieAssetByKey[gift.id];
    return lottieAssetByKey[ref] ?? lottieAssetByKey[gift.id];
  }

  static String? riveAsset(GiftEntity gift) {
    final ref = gift.animationRef;
    if (ref == null) return riveAssetByKey[gift.id];
    return riveAssetByKey[ref] ?? riveAssetByKey[gift.id];
  }

  static String? svgaAsset(GiftEntity gift) {
    final ref = gift.animationRef;
    if (ref == null) return svgaAssetByKey[gift.id];
    return svgaAssetByKey[ref] ?? svgaAssetByKey[gift.id];
  }

  static String emoji(GiftEntity gift) =>
      emojiById[gift.id] ?? emojiById[gift.animationRef ?? ''] ?? '🎁';

  static GiftAnimationKind resolvedKind(GiftEntity gift) {
    if (gift.animationKind != GiftAnimationKind.lottie) {
      return gift.animationKind;
    }
    if (riveAsset(gift) != null) return GiftAnimationKind.rive;
    if (svgaAsset(gift) != null) return GiftAnimationKind.svga;
    if (lottieAsset(gift) != null) return GiftAnimationKind.lottie;
    return GiftAnimationKind.none;
  }
}
