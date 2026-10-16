import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../fortune/domain/entities/user_fortune_entity.dart';
import '../../../fortune/presentation/data/fortune_catalog.dart';

/// Fal türü başına toplam baktıran sayısı (katalog slug'ı → adet).
/// Kaynak: `GET /api/public-stats` → `fortunes.byType` (sunucu anahtarları
/// `coffee`, `tarot`… slug'a çevrilip toplanır).
final fortuneTypeCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  ref.keepAlive();
  final res = await ref.read(dioProvider).safeGet<dynamic>(ApiEndpoints.publicStats);
  final root = res.data is Map ? asJsonMap(res.data) : const <String, dynamic>{};
  final data = root['data'] is Map ? asJsonMap(root['data']) : root;
  final fortunes = data['fortunes'] is Map ? asJsonMap(data['fortunes']) : const <String, dynamic>{};
  final byType = fortunes['byType'] is Map ? asJsonMap(fortunes['byType']) : const <String, dynamic>{};
  final out = <String, int>{};
  byType.forEach((key, value) {
    final n = asInt(value);
    if (n <= 0) return;
    final k = key.toLowerCase().trim();
    final slugKey = UserFortuneEntity.backendKeyToSlug[k] ?? k;
    final slug = FortuneCatalog.bySlug(slugKey)?.slug ?? slugKey;
    out[slug] = (out[slug] ?? 0) + n;
  });
  return out;
});
