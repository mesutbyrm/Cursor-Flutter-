import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/admin/data/admin_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _body(RequestOptions o) {
  final d = o.data;
  if (d is Map) return Map<String, dynamic>.from(d);
  return Map<String, dynamic>.from(jsonDecode(d.toString()) as Map);
}

void main() {
  late _CaptureAdapter adapter;
  late AdminRemoteDataSource remote;

  setUp(() {
    adapter = _CaptureAdapter();
    remote = AdminRemoteDataSource(Dio()..httpClientAdapter = adapter);
  });

  test('jeton yükle → currency jeton, pozitif miktar, tek istek', () async {
    await remote.adjustCredits(userId: 'u1', type: 'jeton', amount: 500, add: true);
    expect(adapter.requests, hasLength(1));
    final r = adapter.requests.single;
    expect(r.method, 'POST');
    expect(r.path, endsWith('/api/admin/credits'));
    final b = _body(r);
    expect(b['userId'], 'u1');
    expect(b['currency'], 'jeton');
    expect(b['amount'], 500);
  });

  test('CFC çıkar → currency credits, eksi miktar', () async {
    await remote.adjustCredits(userId: 'u1', type: 'cfc', amount: 30, add: false);
    final b = _body(adapter.requests.single);
    expect(b['currency'], 'credits');
    expect(b['amount'], -30);
  });
}
