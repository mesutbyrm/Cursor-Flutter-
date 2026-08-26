import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../vip_gold/domain/vip_tier.dart';
import '../domain/cosmetic_effect_kind.dart';
import '../domain/cosmetic_item.dart';
import '../domain/cosmetic_slot.dart';

class CosmeticsRemoteDataSource {
  CosmeticsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CosmeticItem>> fetchProfileFrames() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.profileFrames);
    return _parseCatalog(res.data, defaultSlot: CosmeticSlot.profileFrame);
  }

  Future<List<CosmeticItem>> fetchMembershipBadges() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.membershipBadges);
    final list = _unwrapList(res.data);
    return list
        .map((json) {
          return CosmeticItem(
            id: json['id']?.toString() ?? '',
            slot: CosmeticSlot.badge,
            name: json['name']?.toString() ?? 'Rozet',
            effectKind: CosmeticEffectKind.imageOverlay,
            previewUrl: json['imageUrl']?.toString(),
            assetUrl: json['imageUrl']?.toString(),
            requiredTier: VipTier.fromMembership(json['tier']?.toString()),
          );
        })
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  List<CosmeticItem> _parseCatalog(
    dynamic body, {
    required CosmeticSlot defaultSlot,
  }) {
    final list = _unwrapList(body);
    return list
        .map((m) {
          if (!m.containsKey('slot')) {
            m['slot'] = defaultSlot.apiKey;
          }
          return CosmeticItem.fromJson(m);
        })
        .where((c) => c.id.isNotEmpty && c.active)
        .toList();
  }

  List<Map<String, dynamic>> _unwrapList(dynamic body) {
    if (body is List) {
      return asJsonList(body);
    }
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['success'] == true && map['data'] != null) {
        return _unwrapList(map['data']);
      }
      final items = map['items'] ?? map['frames'] ?? map['data'];
      if (items is List) return asJsonList(items);
    }
    return const [];
  }
}
