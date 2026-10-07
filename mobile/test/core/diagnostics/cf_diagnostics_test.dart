import 'dart:async';

import 'package:canlifal_social/core/diagnostics/cf_diag.dart';
import 'package:canlifal_social/core/diagnostics/cf_monitors.dart';
import 'package:canlifal_social/core/diagnostics/cf_self_check.dart';
import 'package:canlifal_social/core/diagnostics/cf_trace.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dio(String path, {int? status, DioExceptionType? type}) {
  final req = RequestOptions(path: path);
  return DioException(
    requestOptions: req,
    type: type ?? (status != null ? DioExceptionType.badResponse : DioExceptionType.connectionTimeout),
    response: status != null ? Response(requestOptions: req, statusCode: status) : null,
  );
}

void main() {
  setUp(() {
    CfDiag.resetForTest();
    CfTrace.resetForTest();
  });

  group('CfDiag gizlilik', () {
    test('gizli anahtarlar atılır, JWT maskelenir', () {
      final out = CfDiag.sanitize({
        'token': 'abc',
        'accessToken': 'abc',
        'Authorization': 'Bearer x',
        'userSig': 'zzz',
        'email': 'a@b.c',
        'sessionId': 'sess_1',
        'note': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.abcdef',
      });
      expect(out.containsKey('token'), isFalse);
      expect(out.containsKey('accessToken'), isFalse);
      expect(out.containsKey('Authorization'), isFalse);
      expect(out.containsKey('userSig'), isFalse);
      expect(out.containsKey('email'), isFalse);
      expect(out['sessionId'], 'sess_1');
      expect(out['note'], contains('[jwt]'));
      expect(out['note'], isNot(contains('eyJ')));
    });

    test('kayıt mesajındaki Bearer değeri maskelenir', () {
      CfDiag.record(CfCategory.auth, 'hata Bearer abc.def.ghi bitti');
      expect(CfDiag.entries.single.message, isNot(contains('abc.def.ghi')));
    });

    test('CORE-001: yutulan hata warn olarak ve maskeli kaydedilir', () {
      CfDiag.swallowed(
        StateError('token Bearer abc.def.ghi düştü'),
        StackTrace.current,
        CfCategory.trtc,
        'trtc_room_manager:leave',
      );
      final e = CfDiag.entries.single;
      expect(e.category, CfCategory.trtc);
      expect(e.level, CfLevel.warn);
      expect(e.message, contains('swallowed@trtc_room_manager:leave'));
      expect(e.message, isNot(contains('abc.def.ghi')));
    });

    test('halka tampon sınırı aşılmaz', () {
      for (var i = 0; i < CfDiag.maxEntries + 50; i++) {
        CfDiag.record(CfCategory.ui, 'e$i');
      }
      expect(CfDiag.entries.length, CfDiag.maxEntries);
      expect(CfDiag.entries.last.message, 'e${CfDiag.maxEntries + 49}');
    });
  });

  group('CfDiag kategori', () {
    test('TRTC yolu → trtc', () {
      expect(CfDiag.categorize(_dio('/api/trtc/token')), CfCategory.trtc);
    });
    test('401 → auth', () {
      expect(CfDiag.categorize(_dio('/api/x', status: 401)), CfCategory.auth);
    });
    test('zaman aşımı → network', () {
      expect(CfDiag.categorize(_dio('/api/x')), CfCategory.network);
      expect(CfDiag.categorize(TimeoutException('x')), CfCategory.network);
    });
    test('falcı yolu → fortune', () {
      expect(CfDiag.categorize(_dio('/api/fortune-tellers/sessions')),
          CfCategory.fortune);
    });
    test('FormatException → databaseApi', () {
      expect(CfDiag.categorize(const FormatException('json')),
          CfCategory.databaseApi);
    });
    test('FlutterError → ui', () {
      expect(CfDiag.categorize(FlutterError('render overflow')), CfCategory.ui);
    });
    test('bilinmeyen → unknown', () {
      expect(CfDiag.categorize(StateError('x')), CfCategory.unknown);
    });
    test('recordError fırlatmaz ve kategori yazar', () {
      CfDiag.recordError(_dio('/api/trtc/token'), StackTrace.current);
      expect(CfDiag.entries.single.category, CfCategory.trtc);
      expect(CfDiag.entries.single.level, CfLevel.error);
    });
  });

  group('CfTrace', () {
    test('adımlar ölçülür, TOTAL ve traceId oluşur', () async {
      final t = CfTrace.start('FORTUNE_REQUEST', CfCategory.fortune);
      expect(t.traceId, startsWith('CF-TRACE-'));
      await t.timed('API', () => Future<void>.delayed(const Duration(milliseconds: 20)));
      t.step('UI');
      t.finish(outcome: 'ok');
      expect(t.steps.map((s) => s.name), ['API', 'UI']);
      expect(t.steps.first.ms, greaterThanOrEqualTo(15));
      expect(t.totalMs, isNotNull);
      expect(t.format(), contains('TOTAL:'));
      expect(CfTrace.recent.first, same(t));
    });

    test('hatada adım failed işaretlenir ve hata yeniden fırlatılır', () async {
      final t = CfTrace.start('X', CfCategory.fortune);
      await expectLater(
        t.timed('API', () async => throw StateError('boom')),
        throwsStateError,
      );
      expect(t.steps.single.failed, isTrue);
      expect(CfDiag.pendingOps, isEmpty);
    });

    test('bekleyen işlem çalışırken görünür', () async {
      final t = CfTrace.start('X', CfCategory.fortune);
      final c = Completer<void>();
      final f = t.timed('API', () => c.future);
      expect(CfDiag.pendingOps.single, startsWith('X/API'));
      c.complete();
      await f;
      expect(CfDiag.pendingOps, isEmpty);
    });
  });

  group('CfSingleFlight', () {
    test('çalışırken gelen çağrı aynı işi paylaşır', () async {
      final sf = CfSingleFlight<int>();
      var calls = 0;
      final c = Completer<int>();
      Future<int> body() {
        calls++;
        return c.future;
      }

      final a = sf.run(body);
      final b = sf.run(body);
      expect(sf.running, isTrue);
      c.complete(7);
      expect(await a, 7);
      expect(await b, 7);
      expect(calls, 1);
      expect(sf.running, isFalse);
      await sf.run(() async => 1);
      expect(calls, 1);
    });

    test('hata sonrası kilit açılır', () async {
      final sf = CfSingleFlight<int>();
      await expectLater(sf.run(() async => throw StateError('x')), throwsStateError);
      expect(sf.running, isFalse);
      expect(await sf.run(() async => 3), 3);
    });
  });

  group('Donma / kare izleyici (saf mantık)', () {
    test('normal tick donma sayılmaz', () {
      final d = CfFreezeDetector();
      final t0 = DateTime(2026, 1, 1, 12);
      expect(d.onTick(t0), isNull);
      expect(d.onTick(t0.add(const Duration(milliseconds: 250))), isNull);
      expect(d.onTick(t0.add(const Duration(milliseconds: 520))), isNull);
    });

    test('1 sn üstü gecikme donma olarak raporlanır', () {
      final d = CfFreezeDetector();
      final t0 = DateTime(2026, 1, 1, 12);
      d.onTick(t0);
      final f = d.onTick(t0.add(const Duration(milliseconds: 1840)));
      expect(f, isNotNull);
      expect(f!.inMilliseconds, 1590);
    });

    test('reset sonrası (arka plan dönüşü) yanlış alarm yok', () {
      final d = CfFreezeDetector();
      final t0 = DateTime(2026, 1, 1, 12);
      d.onTick(t0);
      d.reset();
      expect(d.onTick(t0.add(const Duration(minutes: 5))), isNull);
    });

    test('kare istatistiği jank eşiğini sayar', () {
      final s = CfFrameStats();
      expect(s.add(buildMs: 8, rasterMs: 6), isNull);
      expect(s.add(buildMs: 87, rasterMs: 10), 87);
      expect(s.frames, 2);
      expect(s.janky, 1);
      expect(s.worstMs, 87);
    });
  });

  group('CfCheckRunner', () {
    test('ok / warn / fail ve süre', () async {
      final r = await CfCheckRunner.runAll([
        CfCheckSpec('a', () async => const CfCheckOutcome.ok('iyi')),
        CfCheckSpec('b', () async => CfCheckOutcome.latency(1800)),
        CfCheckSpec('c', () async => CfCheckOutcome.latency(7000)),
      ]);
      expect(r.map((e) => e.status),
          [CfCheckStatus.ok, CfCheckStatus.warn, CfCheckStatus.fail]);
    });

    test('hata ve zaman aşımı taramayı durdurmaz; JWT sızmaz', () async {
      final results = await CfCheckRunner.runAll([
        CfCheckSpec('hata', () async {
          throw StateError('Bearer abc123 eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.sig');
        }),
        CfCheckSpec(
          'yavaş',
          () => Completer<CfCheckOutcome>().future,
          timeout: const Duration(milliseconds: 30),
        ),
        CfCheckSpec('son', () async => const CfCheckOutcome.ok()),
      ]);
      expect(results.length, 3);
      expect(results[0].status, CfCheckStatus.fail);
      expect(results[0].detail, isNot(contains('abc123')));
      expect(results[0].detail, isNot(contains('eyJ')));
      expect(results[1].status, CfCheckStatus.fail);
      expect(results[1].detail, contains('zaman aşımı'));
      expect(results[2].status, CfCheckStatus.ok);
    });

    test('iptal edilince kalan kontroller çalışmaz', () async {
      var cancelled = false;
      final results = await CfCheckRunner.runAll(
        [
          CfCheckSpec('1', () async {
            cancelled = true;
            return const CfCheckOutcome.ok();
          }),
          CfCheckSpec('2', () async => const CfCheckOutcome.ok()),
        ],
        isCancelled: () => cancelled,
      );
      expect(results.length, 1);
    });
  });
}
