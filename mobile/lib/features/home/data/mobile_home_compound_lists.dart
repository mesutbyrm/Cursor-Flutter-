/// `GET /api/mobile/home` gövdesindeki ortak liste anahtarları.
abstract final class MobileHomeCompoundLists {
  static const fanClubKeys = ['fanClubs', 'popularFanClubs', 'clubs'];

  static const dailyRewardKeys = ['dailyRewards', 'rewards', 'dailyReward'];

  /// İlk dolu liste veya tek nesne satırı.
  static List<dynamic> rows(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final v = raw[key];
      if (v is List && v.isNotEmpty) return v;
      if (v is Map && v.isNotEmpty) return [v];
    }
    return const [];
  }
}
