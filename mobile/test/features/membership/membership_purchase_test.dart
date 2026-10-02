import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/membership/data/membership_remote_datasource.dart';
import 'package:canlifal_social/features/membership/domain/membership_purchase_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  /// (path, body) → (status, json/text body)
  final (int, Object?) Function(String path, Object? body) respond;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add('${options.method} ${options.path}');
    final (status, data) = respond(options.path, options.data);
    final text = data is String ? data : jsonEncode(data);
    return ResponseBody.fromString(
      text,
      status,
      headers: {
        Headers.contentTypeHeader: [
          data is String ? 'text/html' : 'application/json',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MembershipRemoteDataSource _ds(_Adapter a) {
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))
    ..httpClientAdapter = a;
  return MembershipRemoteDataSource(dio);
}

void main() {
  test('404 JSON "Plan not found" kesin cevaptır: tek deneme, Türkçe mesaj, ayrıntı',
      () async {
    final a = _Adapter((p, b) => (404, {'error': 'Plan not found'}));
    Object? err;
    try {
      await _ds(a).purchaseMembership('svip', paymentMethod: 'jeton', planLabel: 'SVIP');
    } catch (e) {
      err = e;
    }
    expect(err, isA<MembershipPurchaseException>());
    final e = err! as MembershipPurchaseException;
    expect(a.calls, hasLength(1)); // eskiden ~18 tekrar → 429 gerçek hatayı gizliyordu
    expect(e.statusCode, 404);
    expect(e.message, contains('SVIP planı sunucuda bulunamadı'));
    expect(e.serverMessage, 'Plan not found');
    expect(e.technicalReport, contains('planId: svip'));
    expect(e.technicalReport, contains('Plan not found'));
    expect(e.technicalReport, contains('"paymentMethod"'.replaceAll('"', '')));
  });

  test('HTML 404 (yol yok) → ikinci yol denenir', () async {
    final a = _Adapter((p, b) => p == '/api/memberships/purchase'
        ? (404, '<html>not found</html>')
        : (200, {'success': true}));
    await _ds(a).purchaseMembership('cl123abc', paymentMethod: 'jeton');
    expect(a.calls, [
      'POST /api/memberships/purchase',
      'POST /api/membership/purchase',
    ]);
  });

  test('yetersiz jeton mesajı korunur', () async {
    final a = _Adapter((p, b) => (400, {'error': 'Yetersiz jeton bakiyesi'}));
    Object? err;
    try {
      await _ds(a).purchaseMembership('cl123abc', paymentMethod: 'jeton');
    } catch (e) {
      err = e;
    }
    expect((err! as MembershipPurchaseException).message, 'Yetersiz jeton bakiyesi');
  });

  test('looksLikeServerPlanId: tier adı gerçek plan kimliği değildir', () {
    expect(looksLikeServerPlanId('svip'), isFalse);
    expect(looksLikeServerPlanId('gold'), isFalse);
    expect(looksLikeServerPlanId('clxyz1234567890abcdef'), isTrue);
    expect(looksLikeServerPlanId(''), isFalse);
  });
}
