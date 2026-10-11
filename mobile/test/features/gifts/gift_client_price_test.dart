import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/gifts/data/gift_client_price.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('giftClientPriceFields omits invalid prices', () {
    expect(giftClientPriceFields(null), isEmpty);
    expect(giftClientPriceFields(0), isEmpty);
    expect(giftClientPriceFields(99), {'clientPrice': 99});
  });

  test('ApiException.fromDio maps 409 PRICE_MISMATCH', () {
    final ex = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/api/gifts/send'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/gifts/send'),
          statusCode: 409,
          data: {
            'code': 'PRICE_MISMATCH',
            'message': 'Fiyat değişti',
            'serverPrice': 120,
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(ex.statusCode, 409);
    expect(ex.errorCode, 'PRICE_MISMATCH');
    expect(isGiftPriceMismatch(ex), isTrue);
    expect(giftSendUserMessage(ex), giftPriceMismatchUserMessage);
  });
}
