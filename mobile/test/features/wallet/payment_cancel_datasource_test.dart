import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:canlifal_social/features/wallet/data/wallet_remote_datasource_extended.dart';
import 'package:canlifal_social/features/wallet/domain/withdrawal_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yanıtları yola göre veren, istekleri kaydeden Dio.
Dio _dio(Map<String, (int, Object?)> routes, List<String> calls) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        calls.add('${o.method} ${o.path}');
        final r = routes[o.path] ?? (404, {'error': 'yok'});
        final res = Response<dynamic>(requestOptions: o, statusCode: r.$1, data: r.$2);
        if (r.$1 >= 400) {
          return h.reject(DioException.badResponse(statusCode: r.$1, requestOptions: o, response: res));
        }
        h.resolve(res);
      },
    ),
  );
  return dio;
}

void main() {
  group('WithdrawalRequest.cancellable', () {
    WithdrawalRequest w(String s) => WithdrawalRequest(id: 'w', amount: 1, status: s);

    test('yalnız bekleyen ve ajans onaylı iptal edilebilir', () {
      expect(w('pending').cancellable, isTrue);
      expect(w('agency_approved').cancellable, isTrue);
      expect(w('approved').cancellable, isFalse);
      expect(w('completed').cancellable, isFalse);
      expect(w('cancelled').cancellable, isFalse);
      expect(w('cancelled').statusLabel, 'İptal edildi');
    });
  });

  test('para çekme iptali doğru uca gider; 409 mesajı aynen döner', () async {
    final calls = <String>[];
    final ok = WalletRemoteDataSourceExtended(
      _dio({'/api/withdrawals/w1/cancel': (200, {'success': true})}, calls),
    );
    await ok.cancelWithdrawal('w1');
    expect(calls, ['POST /api/withdrawals/w1/cancel']);

    final conflict = WalletRemoteDataSourceExtended(
      _dio({
        '/api/withdrawals/w2/cancel': (409, {'error': {'code': 'conflict', 'message': 'Talep işlendi, iptal edilemez'}}),
      }, calls),
    );
    await expectLater(
      conflict.cancelWithdrawal('w2'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Talep işlendi, iptal edilemez')),
    );
  });

  test('CFC talebi yoksa (404) ödeme bildirimi iptaline düşer', () async {
    final calls = <String>[];
    final ds = WalletRemoteDataSource(
      _dio({'/api/payments/notify/p1/cancel': (200, {'success': true})}, calls),
      TokenStorage(const FlutterSecureStorage()),
    );
    await ds.cancelPaymentRequest('p1');
    expect(calls, ['POST /api/payments/requests/p1/cancel', 'POST /api/payments/notify/p1/cancel']);
  });

  test('CFC talebi iptalinde 400 hatası düşmeden aynen gösterilir', () async {
    final calls = <String>[];
    final ds = WalletRemoteDataSource(
      _dio({
        '/api/payments/requests/c1/cancel': (400, {'success': false, 'error': 'Yalnızca bekleyen talepler iptal edilebilir'}),
      }, calls),
      TokenStorage(const FlutterSecureStorage()),
    );
    await expectLater(
      ds.cancelPaymentRequest('c1'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Yalnızca bekleyen talepler iptal edilebilir')),
    );
    expect(calls, ['POST /api/payments/requests/c1/cancel']);
  });
}
