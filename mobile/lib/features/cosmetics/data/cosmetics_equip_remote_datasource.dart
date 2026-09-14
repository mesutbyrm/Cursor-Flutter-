import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../domain/cosmetic_slot.dart';
import '../domain/user_cosmetic_loadout.dart';

/// Kozmetik equip — backend hazır olduğunda senkron (404’te sessiz).
class CosmeticsEquipRemoteDataSource {
  CosmeticsEquipRemoteDataSource(this._dio);

  final Dio _dio;

  static const _equipPaths = [
    ApiEndpoints.userCosmeticsEquip,
    ApiEndpoints.userProfileCosmeticsEquip,
  ];

  static const _loadoutPaths = [
    ApiEndpoints.userCosmeticsLoadout,
    ApiEndpoints.userCosmetics,
  ];

  Future<UserCosmeticLoadout?> fetchRemoteLoadout() async {
    for (final path in _loadoutPaths) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        if (res.statusCode == 404) continue;
        final body = res.data;
        if (body is Map) {
          return UserCosmeticLoadout.fromJson(Map<String, dynamic>.from(body));
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> pushEquip(CosmeticSlot slot, String? itemId) async {
    for (final path in _equipPaths) {
      try {
        final res = await _dio.safePost<dynamic>(
          path,
          data: {
            'slot': slot.apiKey,
            'itemId': itemId,
          },
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        if (res.statusCode != null && res.statusCode! < 400) return;
      } catch (_) {}
    }
  }
}
