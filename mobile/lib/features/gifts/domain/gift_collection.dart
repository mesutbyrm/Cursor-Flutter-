import '../../../core/util/json_util.dart';

/// Bir hediye türünün koleksiyon/albüm kaydı (kaç adet gönderildi/alındı).
class GiftCollectionItem {
  const GiftCollectionItem({
    required this.giftId,
    required this.name,
    this.iconUrl,
    this.count = 0,
    this.rarity,
  });

  factory GiftCollectionItem.fromJson(Map<String, dynamic> json) {
    return GiftCollectionItem(
      giftId: (pick(json, ['giftId', 'giftTypeId', 'id', 'slug']) ?? '')
          .toString(),
      name: (pick(json, ['name', 'nameTr', 'label']) ?? '').toString(),
      iconUrl: pick(json, ['icon', 'iconUrl', 'image'])?.toString(),
      count: asInt(pick(json, ['count', 'quantity', 'total', 'qty'])),
      rarity: pick(json, ['rarity'])?.toString(),
    );
  }

  final String giftId;
  final String name;
  final String? iconUrl;
  final int count;
  final String? rarity;
}

/// Hediye koleksiyonu — `/api/gifts/insights/collection/{userId}`.
/// Gönderilen/alınan hediye türleri + tamamlanma yüzdesi.
class GiftCollection {
  const GiftCollection({
    this.totalGiftTypes = 0,
    this.distinctReceived = 0,
    this.distinctSent = 0,
    this.percent = 0,
    this.sent = const [],
    this.received = const [],
  });

  factory GiftCollection.fromJson(Map<String, dynamic> json) {
    final comp = pick(json, ['completion']);
    final compMap = comp is Map ? asJsonMap(comp) : <String, dynamic>{};
    List<GiftCollectionItem> parse(dynamic raw) {
      final out = <GiftCollectionItem>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) out.add(GiftCollectionItem.fromJson(asJsonMap(e)));
        }
      }
      return out;
    }

    return GiftCollection(
      totalGiftTypes: asInt(pick(compMap, ['totalGiftTypes', 'total'])),
      distinctReceived: asInt(pick(compMap, ['distinctReceived'])),
      distinctSent: asInt(pick(json, ['distinctSent'])),
      percent: asInt(pick(compMap, ['percent'])),
      sent: parse(pick(json, ['sent'])),
      received: parse(pick(json, ['received'])),
    );
  }

  final int totalGiftTypes;
  final int distinctReceived;
  final int distinctSent;
  final int percent;
  final List<GiftCollectionItem> sent;
  final List<GiftCollectionItem> received;
}

/// Hediye albümü — `/api/gifts/insights/album/{userId}`.
/// Alınan benzersiz hediyeler (3D/vitrin görünümü).
class GiftAlbum {
  const GiftAlbum({this.totalDistinct = 0, this.items = const []});

  factory GiftAlbum.fromJson(Map<String, dynamic> json) {
    final raw = pick(json, ['items', 'gifts', 'data']);
    final items = <GiftCollectionItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) items.add(GiftCollectionItem.fromJson(asJsonMap(e)));
      }
    }
    return GiftAlbum(
      totalDistinct: asInt(pick(json, ['totalDistinct', 'total'])),
      items: items,
    );
  }

  final int totalDistinct;
  final List<GiftCollectionItem> items;
}

/// Efsane İlk Destekçi — `/api/gifts/insights/first-gifter/{ctx}/{id}`.
class FirstGifter {
  const FirstGifter({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.amount = 0,
    this.at,
  });

  static FirstGifter? fromResponse(Map<String, dynamic> json) {
    final raw = pick(json, ['firstGifter', 'gifter', 'data']);
    final m = raw is Map ? asJsonMap(raw) : (raw == null ? null : json);
    if (m == null) return null;
    final id = (pick(m, ['userId', 'id']) ?? '').toString();
    if (id.isEmpty) return null;
    return FirstGifter(
      userId: id,
      displayName:
          (pick(m, ['displayName', 'name', 'username']) ?? '').toString(),
      avatarUrl: pick(m, ['avatarUrl', 'avatar', 'image'])?.toString(),
      amount: asInt(pick(m, ['amount', 'coins', 'total'])),
      at: DateTime.tryParse(pick(m, ['at', 'createdAt', 'date'])?.toString() ?? ''),
    );
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int amount;
  final DateTime? at;
}
