import '../../../core/util/json_util.dart';

/// Küçük yardımcı — büyük tutarları gizleyerek kısaltır (1K/1M). Gerçek gelir
/// asla ham gösterilmez.
String compactAmount(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

/// Basit isim/değer satırı (en çok gönderilen, en çok kazanan).
class AdminGiftRankRow {
  const AdminGiftRankRow({required this.label, this.value = 0, this.iconUrl});

  factory AdminGiftRankRow.fromJson(Map<String, dynamic> json) {
    return AdminGiftRankRow(
      label: (pick(json, ['name', 'label', 'displayName', 'giftName', 'title']) ??
              '—')
          .toString(),
      value: asInt(pick(json, ['value', 'count', 'total', 'coins', 'amount'])),
      iconUrl: pick(json, ['icon', 'iconUrl', 'avatarUrl', 'image'])?.toString(),
    );
  }

  final String label;
  final int value;
  final String? iconUrl;
}

/// Hediye istatistikleri — `/api/admin/gifts/statistics`.
class AdminGiftStats {
  const AdminGiftStats({
    this.totalGifts = 0,
    this.totalCoins = 0,
    this.siteRevenue = 0,
    this.topSent = const [],
    this.topEarners = const [],
  });

  factory AdminGiftStats.fromJson(Map<String, dynamic> json) {
    List<AdminGiftRankRow> parse(dynamic raw) {
      final out = <AdminGiftRankRow>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) out.add(AdminGiftRankRow.fromJson(asJsonMap(e)));
        }
      }
      return out;
    }

    return AdminGiftStats(
      totalGifts: asInt(pick(json, ['totalGifts', 'totalCount', 'total'])),
      totalCoins: asInt(pick(json, ['totalCoins', 'totalAmount', 'coins'])),
      siteRevenue: asInt(
          pick(json, ['siteRevenue', 'revenue', 'siteEarnings', 'siteShare'])),
      topSent: parse(pick(json, ['topSent', 'mostSent', 'topGifts'])),
      topEarners: parse(pick(json, ['topEarners', 'topReceivers', 'earners'])),
    );
  }

  final int totalGifts;
  final int totalCoins;
  final int siteRevenue;
  final List<AdminGiftRankRow> topSent;
  final List<AdminGiftRankRow> topEarners;
}

/// Gelir paylaşım kuralı — `/api/admin/gifts/revenue/rules`.
/// Kod değişmeden düzenlenebilir (site/sahip/alıcı yüzdeleri).
class AdminRevenueRule {
  const AdminRevenueRule({
    required this.context,
    this.sitePercent = 0,
    this.ownerPercent = 0,
    this.receiverPercent = 0,
  });

  factory AdminRevenueRule.fromJson(Map<String, dynamic> json) {
    return AdminRevenueRule(
      context: (pick(json, ['context', 'key', 'name']) ?? '').toString(),
      sitePercent:
          asInt(pick(json, ['sitePercent', 'site', 'siteShare', 'platform'])),
      ownerPercent:
          asInt(pick(json, ['ownerPercent', 'owner', 'ownerShare', 'host'])),
      receiverPercent: asInt(
          pick(json, ['receiverPercent', 'receiver', 'receiverShare', 'user'])),
    );
  }

  final String context;
  final int sitePercent;
  final int ownerPercent;
  final int receiverPercent;

  int get total => sitePercent + ownerPercent + receiverPercent;
}
