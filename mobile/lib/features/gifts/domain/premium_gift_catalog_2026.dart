import 'gift_animation_kind.dart';
import 'gift_entity.dart';
import 'gift_rarity.dart';

/// TikTok Live seviyesi — 8 premium hediye tanımı (API id eşlemesi dahil).
abstract final class PremiumGiftCatalog2026 {
  static const giftIds = [
    'roket',
    'galaksi',
    'aslan',
    'araba',
    'elmas',
    'kalp',
    'tac',
    'yat',
  ];

  static const _defs = <_PremiumDef>[
    _PremiumDef(
      id: 'roket',
      displayName: 'Roket',
      emoji: '🚀',
      rarity: GiftRarity.epic,
      animationKind: GiftAnimationKind.lottie,
      animationRef: 'lottie:car',
      aliases: ['roket', 'rocket'],
      coinCostHint: 120,
    ),
    _PremiumDef(
      id: 'galaksi',
      displayName: 'Galaxy',
      emoji: '🌌',
      rarity: GiftRarity.legendary,
      animationKind: GiftAnimationKind.svga,
      animationRef: 'svga:galaxy',
      aliases: ['galaksi', 'galaxy'],
      coinCostHint: 500,
    ),
    _PremiumDef(
      id: 'aslan',
      displayName: 'Aslan',
      emoji: '🦁',
      rarity: GiftRarity.legendary,
      animationKind: GiftAnimationKind.rive,
      animationRef: 'rive:lion',
      aliases: ['aslan', 'lion'],
      coinCostHint: 350,
    ),
    _PremiumDef(
      id: 'araba',
      displayName: 'Spor araba',
      emoji: '🏎️',
      rarity: GiftRarity.epic,
      animationKind: GiftAnimationKind.lottie,
      animationRef: 'lottie:car',
      aliases: ['araba', 'car', 'spor_araba', 'sportscar'],
      coinCostHint: 200,
    ),
    _PremiumDef(
      id: 'elmas',
      displayName: 'Elmas',
      emoji: '💎',
      rarity: GiftRarity.mythic,
      animationKind: GiftAnimationKind.rive,
      animationRef: 'rive:diamond',
      aliases: ['elmas', 'diamond'],
      coinCostHint: 999,
    ),
    _PremiumDef(
      id: 'kalp',
      displayName: 'Kalp',
      emoji: '💖',
      rarity: GiftRarity.rare,
      animationKind: GiftAnimationKind.lottie,
      animationRef: 'lottie:heart',
      aliases: ['kalp', 'heart', 'gul'],
      coinCostHint: 30,
    ),
    _PremiumDef(
      id: 'tac',
      displayName: 'Taç',
      emoji: '👑',
      rarity: GiftRarity.epic,
      animationKind: GiftAnimationKind.lottie,
      animationRef: 'lottie:crown',
      aliases: ['tac', 'crown', 'yildiz'],
      coinCostHint: 150,
    ),
    _PremiumDef(
      id: 'yat',
      displayName: 'Yat',
      emoji: '🛥️',
      rarity: GiftRarity.mythic,
      animationKind: GiftAnimationKind.lottie,
      animationRef: 'lottie:star',
      aliases: ['yat', 'yacht'],
      coinCostHint: 800,
    ),
  ];

  static final _byId = {for (final d in _defs) d.id: d};
  static final _aliasToId = {
    for (final d in _defs)
      for (final a in d.aliases) a: d.id,
  };

  static String? canonicalId(String raw) {
    final k = raw.toLowerCase().trim();
    if (_byId.containsKey(k)) return k;
    return _aliasToId[k];
  }

  static _PremiumDef? defFor(String giftId) {
    final id = canonicalId(giftId);
    if (id == null) return null;
    return _byId[id];
  }

  static String displayName(String giftId, {String? fallback}) {
    return defFor(giftId)?.displayName ?? fallback ?? giftId;
  }

  static String emoji(String giftId) => defFor(giftId)?.emoji ?? '🎁';

  static GiftRarity rarity(String giftId) =>
      defFor(giftId)?.rarity ?? GiftRarity.common;

  static bool triggersFullscreen({
    required String giftId,
    required int coinCost,
    required int combo,
  }) {
    final r = rarity(giftId);
    if (r.index >= GiftRarity.epic.index) return true;
    if (coinCost >= 100) return true;
    if (combo >= 3) return true;
    return false;
  }

  static GiftEntity entityForCatalogRow({
    required String id,
    required String name,
    required int price,
  }) {
    final def = defFor(id);
    if (def == null) {
      return GiftEntity(id: id, name: name, price: price);
    }
    return GiftEntity(
      id: def.id,
      name: def.displayName,
      price: price,
      animationRef: def.animationRef,
      animationKind: def.animationKind,
      rarity: def.rarity,
    );
  }

  /// API listesini premium sıraya göre düzenler; bilinmeyenler sona eklenir.
  static List<T> sortCatalog<T>(
    List<T> items,
    String Function(T) idOf,
  ) {
    final order = {for (var i = 0; i < giftIds.length; i++) giftIds[i]: i};
    final copy = [...items];
    copy.sort((a, b) {
      final ia = order[canonicalId(idOf(a)) ?? idOf(a)] ?? 99;
      final ib = order[canonicalId(idOf(b)) ?? idOf(b)] ?? 99;
      if (ia != ib) return ia.compareTo(ib);
      return idOf(a).compareTo(idOf(b));
    });
    return copy;
  }
}

class _PremiumDef {
  const _PremiumDef({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.rarity,
    required this.animationKind,
    required this.animationRef,
    required this.aliases,
    required this.coinCostHint,
  });

  final String id;
  final String displayName;
  final String emoji;
  final GiftRarity rarity;
  final GiftAnimationKind animationKind;
  final String animationRef;
  final List<String> aliases;
  final int coinCostHint;
}
