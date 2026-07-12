import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/gifts/data/admin_gift_remote_datasource.dart';
import 'package:canlifal_social/features/gifts/presentation/pages/admin_gift_editor_page.dart';
import 'package:canlifal_social/features/gifts/presentation/providers/admin_gift_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminGiftRemoteDataSource.createGift', () {
    test('POSTs the existing DTO and accepts HTTP 201', () async {
      RequestOptions? captured;
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          captured = options;
          return _jsonResponse(201, {
            'gift': {
              'id': 'gift-new-1',
              'name': 'Test Hediye',
              'price': 25,
              'isActive': true,
            },
          });
        }),
      );
      final remote = AdminGiftRemoteDataSource(dio);
      final body = <String, dynamic>{
        'name': 'Test Hediye',
        'nameEn': 'Test Gift',
        'price': 25,
        'animationType': 'none',
        'isActive': true,
      };

      final created = await remote.createGift(body);

      expect(created.id, 'gift-new-1');
      expect(captured?.method, 'POST');
      expect(captured?.path, '/api/admin/gifts');
      expect(captured?.data, body);
    });

    test('rejects HTTP success without a persisted gift id', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, __, ___) => _jsonResponse(200, {'success': true})),
      );
      final remote = AdminGiftRemoteDataSource(dio);

      await expectLater(
        remote.createGift({'name': 'Eksik', 'price': 1}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('geçerli hediye kaydı döndürmedi'),
          ),
        ),
      );
    });

    test('cancels a stuck create request and returns a real timeout', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, __, ___) => Completer<ResponseBody>().future),
      );
      final remote = AdminGiftRemoteDataSource(
        dio,
        operationTimeout: const Duration(milliseconds: 30),
      );

      await expectLater(
        remote.createGift({'name': 'Takılma Testi', 'price': 1}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('zaman aşımına uğradı'),
          ),
        ),
      );
    });
  });

  group('AdminGiftRemoteDataSource.uploadAsset', () {
    test(
      'uploads bytes then returns cloud path separately from public URL',
      () async {
        RequestOptions? presignRequest;
        RequestOptions? putRequest;
        final mainDio = _dioWithAdapter(
          _FakeAdapter((options, _, __) {
            presignRequest = options;
            return _jsonResponse(201, {
              'data': {
                'uploadUrl': 'https://r2.example.test/signed-put',
                'cloudPath': 'gifts/icons/new-gift.png',
                'publicUrl':
                    'https://cdn.example.test/gifts/icons/new-gift.png',
              },
            });
          }),
        );
        final uploadDio = _dioWithAdapter(
          _FakeAdapter((options, _, __) {
            putRequest = options;
            return ResponseBody.fromString('', 200);
          }),
        );
        final remote = AdminGiftRemoteDataSource(
          mainDio,
          uploadDioFactory: () => uploadDio,
        );
        final file = File(
          '${Directory.systemTemp.path}/admin-gift-${DateTime.now().microsecondsSinceEpoch}.png',
        );
        addTearDown(() async {
          if (await file.exists()) await file.delete();
        });
        await file.writeAsBytes([1, 2, 3, 4]);

        final uploaded = await remote.uploadAsset(file, kind: 'icon');

        expect(presignRequest?.path, '/api/admin/gifts/upload-url');
        expect(presignRequest?.data, {
          'fileName': file.path.split(Platform.pathSeparator).last,
          'contentType': 'image/png',
          'kind': 'icon',
          'fileSize': 4,
        });
        expect(putRequest?.method, 'PUT');
        expect(
          putRequest?.uri.toString(),
          'https://r2.example.test/signed-put',
        );
        expect(uploaded.cloudPath, 'gifts/icons/new-gift.png');
        expect(
          uploaded.publicUrl,
          'https://cdn.example.test/gifts/icons/new-gift.png',
        );
      },
    );

    test('falls back to site presigned upload when admin presign times out', () async {
      var call = 0;
      final mainDio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          call++;
          if (options.path == '/api/admin/gifts/upload-url') {
            return Completer<ResponseBody>().future;
          }
          if (options.path == '/api/upload/presigned') {
            return _jsonResponse(201, {
              'success': true,
              'data': {
                'uploadUrl': 'https://r2.example.test/fallback-put',
                'cloud_storage_path': 'gifts/icons/fallback.png',
                'publicUrl': 'https://cdn.example.test/gifts/icons/fallback.png',
              },
            });
          }
          return ResponseBody.fromString('{}', 404);
        }),
      );
      final uploadDio = _dioWithAdapter(
        _FakeAdapter((options, _, __) {
          expect(options.method, 'PUT');
          return ResponseBody.fromString('', 200);
        }),
      );
      final remote = AdminGiftRemoteDataSource(
        mainDio,
        operationTimeout: const Duration(milliseconds: 30),
        uploadDioFactory: () => uploadDio,
      );
      final file = File(
        '${Directory.systemTemp.path}/admin-gift-fallback-${DateTime.now().microsecondsSinceEpoch}.png',
      );
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      await file.writeAsBytes([9, 8, 7]);

      final uploaded = await remote.uploadAsset(file, kind: 'icon');

      expect(call, greaterThanOrEqualTo(2));
      expect(uploaded.cloudPath, 'gifts/icons/fallback.png');
      expect(uploaded.publicUrl, 'https://cdn.example.test/gifts/icons/fallback.png');
    });

    test('listGifts times out instead of hanging forever', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, __, ___) => Completer<ResponseBody>().future),
      );
      final remote = AdminGiftRemoteDataSource(
        dio,
        operationTimeout: const Duration(milliseconds: 30),
      );

      await expectLater(
        remote.listGifts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Hediye kataloğu yükleme'),
          ),
        ),
      );
    });

    test('fails explicitly when presign response has no cloud path', () async {
      final mainDio = _dioWithAdapter(
        _FakeAdapter(
          (_, __, ___) => _jsonResponse(200, {
            'uploadUrl': 'https://r2.example.test/signed-put',
            'publicUrl': 'https://cdn.example.test/gift.png',
          }),
        ),
      );
      final remote = AdminGiftRemoteDataSource(mainDio);
      final file = File(
        '${Directory.systemTemp.path}/admin-gift-missing-path.png',
      );
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      await file.writeAsBytes([1]);

      await expectLater(
        remote.uploadAsset(file, kind: 'icon'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('R2/S3 kayıt yolu'),
          ),
        ),
      );
    });
  });

  testWidgets('Kaydet loading always closes when create request is stuck', (
    tester,
  ) async {
    final dio = _dioWithAdapter(
      _FakeAdapter((_, __, ___) => Completer<ResponseBody>().future),
    );
    final remote = AdminGiftRemoteDataSource(
      dio,
      operationTimeout: const Duration(milliseconds: 30),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminGiftRemoteProvider.overrideWithValue(remote)],
        child: const MaterialApp(home: AdminGiftEditorPage()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Türkçe isim *'),
      350,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Türkçe isim *'),
      'Loading Testi',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Jeton fiyatı *'),
      '10',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Kaydet'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(find.textContaining('zaman aşımına uğradı'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Kaydet'),
    );
    expect(button.onPressed, isNotNull);
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://canlifalapi.example.test',
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

ResponseBody _jsonResponse(int status, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _Responder =
    FutureOr<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    );

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final _Responder responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return responder(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
