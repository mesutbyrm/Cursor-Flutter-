import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/jeton_price_quote.dart';

/// Jeton fiyatı sunucudan alınır; istemci indirim/bonus hesaplamaz.
class JetonPriceService {
  JetonPriceService(this._dio);

  final Dio _dio;

  static const path = '/api/public/jeton-price';

  Future<JetonPriceQuote> quote(int jeton) async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      path,
      query: {'jeton': jeton},
      forceRefresh: true,
    );
    final body = res.data;
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Fiyat alınamadı. Lütfen tekrar deneyin.');
    }
    final q = JetonPriceQuote.fromJson(body);
    if (q.finalAmount <= 0) {
      throw const ApiException('Fiyat alınamadı. Lütfen tekrar deneyin.');
    }
    return q;
  }
}

final jetonPriceServiceProvider = Provider<JetonPriceService>(
  (ref) => JetonPriceService(ref.watch(dioProvider)),
);

final jetonQuoteProvider =
    FutureProvider.autoDispose.family<JetonPriceQuote, int>(
  (ref, jeton) => ref.watch(jetonPriceServiceProvider).quote(jeton),
);
