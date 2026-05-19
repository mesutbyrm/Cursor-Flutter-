import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_gift_type.dart';

class LiveGiftsRemoteDataSource {
  LiveGiftsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LiveVideoGiftType>> fetchGiftTypes() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.videoStreamGiftsCatalog);
    final data = res.data;
    if (data is! List) return const [];
    return data
        .map((e) => LiveVideoGiftType.fromJson(asJsonMap(e)))
        .where((g) => g.id.isNotEmpty)
        .toList();
  }

  /// Site ile aynı gövde: `{ giftTypeId, quantity: 1 }` → yanıtta `newBalance` olabilir.
  Future<int?> sendGift({
    required String streamId,
    required String giftTypeId,
    int quantity = 1,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.videoStreamGifts(streamId),
      data: {'giftTypeId': giftTypeId, 'quantity': quantity},
    );
    final b = res.data;
    if (b == null) return null;
    return asInt(pick(b, ['newBalance', 'balance', 'credits', 'coinBalance']));
  }
}
