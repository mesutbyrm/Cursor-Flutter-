import 'live_gift_type.dart';

/// TikTok tarzı öne çıkan hediyeler (API id → görünen ad).
class LiveGiftCatalog {
  LiveGiftCatalog._();

  static const featuredIds = ['gul', 'kalp', 'yildiz', 'tac', 'roket'];

  static const displayNameOverrides = <String, String>{
    'roket': 'Araba',
  };

  static const lottieAssetById = <String, String>{
    'gul': 'assets/gifts/lottie/rose.json',
    'kalp': 'assets/gifts/lottie/heart.json',
    'yildiz': 'assets/gifts/lottie/star.json',
    'tac': 'assets/gifts/lottie/crown.json',
    'roket': 'assets/gifts/lottie/car.json',
  };

  static const emojiById = <String, String>{
    'gul': '🌹',
    'kalp': '💖',
    'yildiz': '⭐',
    'tac': '👑',
    'roket': '🚗',
    'elmas': '💎',
    'galaksi': '🌌',
  };

  static String displayName(LiveVideoGiftType gift) {
    return displayNameOverrides[gift.id] ?? gift.name;
  }

  static List<LiveVideoGiftType> featuredFrom(List<LiveVideoGiftType> all) {
    final map = {for (final g in all) g.id: g};
    final out = <LiveVideoGiftType>[];
    for (final id in featuredIds) {
      final g = map[id];
      if (g != null) out.add(g);
    }
    if (out.isEmpty) {
      return all.take(5).toList();
    }
    return out;
  }
}
