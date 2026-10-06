// Gerçek PsychicVideoController'ı sahte repo ile çalıştırıp yoklama (900 ms
// sinyal / 2 sn oda) davranışını ÖLÇER: toplam istek, aynı anda uçuşta en çok
// istek, dispose sonrası sızıntı, SSE/TRTC durumu.
//
// Aynı dosya düzeltme öncesi controller'a karşı da çalıştırılabilir (yalnız
// public provider kullanır); bkz. docs/CANLIFAL_PERFORMANCE_DIAGNOSTIC_REPORT.md.
import 'dart:async';

import 'package:canlifal_social/core/network/connectivity/connectivity_service.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_room_sse_service.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_video_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/trtc/data/datasources/trtc_remote_datasource.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';
import 'package:canlifal_social/features/trtc/presentation/providers/trtc_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_live_psychics_repository.dart';

enum _Mode { ok, slow, hang, fail }

class _ProbeRepo extends FakeLivePsychicsRepository {
  _Mode mode = _Mode.ok;
  Duration latency = const Duration(milliseconds: 40);
  final calls = <String, int>{};
  final inFlight = <String, int>{};
  final maxInFlight = <String, int>{};

  int get total => calls.values.fold(0, (a, b) => a + b);
  int get worstConcurrency =>
      maxInFlight.values.fold(0, (a, b) => a > b ? a : b);

  Future<T> _call<T>(String name, T value) async {
    calls[name] = (calls[name] ?? 0) + 1;
    final now = (inFlight[name] ?? 0) + 1;
    inFlight[name] = now;
    if (now > (maxInFlight[name] ?? 0)) maxInFlight[name] = now;
    try {
      switch (mode) {
        case _Mode.hang:
          await Completer<void>().future;
        case _Mode.fail:
          await Future<void>.delayed(latency);
          throw StateError('network down');
        case _Mode.slow:
        case _Mode.ok:
          await Future<void>.delayed(latency);
      }
      return value;
    } finally {
      inFlight[name] = (inFlight[name] ?? 1) - 1;
    }
  }

  @override
  Future<PsychicRoomEntity?> fetchRoom(String sessionId) =>
      _call<PsychicRoomEntity?>('fetchRoom', null);

  @override
  Future<PsychicSessionStatusResult?> fetchSessionStatus(String sessionId) =>
      _call<PsychicSessionStatusResult?>('fetchSessionStatus', null);

  @override
  Future<List<Map<String, dynamic>>> fetchRoomSignals(String sessionId) =>
      _call<List<Map<String, dynamic>>>('fetchRoomSignals', const []);

  @override
  Future<List<PsychicChatMessage>> fetchMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      _call<List<PsychicChatMessage>>('fetchMessages', const []);

  @override
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) =>
      _call<Map<String, dynamic>?>('roomAction', null);

  @override
  Future<void> sendRoomSignal({
    required String sessionId,
    required String type,
    Map<String, dynamic>? data,
    String? receiverId,
  }) =>
      _call<void>('sendRoomSignal', null);
}

class _FakeSse extends PsychicRoomSseService {
  int connectCalls = 0;
  int disconnectCalls = 0;
  final disconnectedFor = <String?>[];
  Duration delay = Duration.zero;

  @override
  Future<void> connect({
    required String sessionId,
    required Future<String?> Function() accessToken,
    Future<bool> Function()? refreshTokens,
    String? myUserId,
    void Function()? onConnected,
    void Function(PsychicChatMessage message)? onMessage,
    void Function(PsychicRoomEntity room)? onRoomUpdate,
    void Function(PsychicSessionStatus status)? onSessionEnded,
    void Function(int amount, String? fromName, String? eventId)? onTipReceived,
    void Function(String type, Map<String, dynamic>? data)? onSignal,
    void Function()? onFailed,
  }) async {
    connectCalls++;
    await Future<void>.delayed(delay);
    onConnected?.call();
  }

  @override
  Future<void> disconnect({String? forSessionId}) async {
    disconnectCalls++;
    disconnectedFor.add(forSessionId);
  }
}

class _FakeConn implements ConnectivityService {
  final _c = StreamController<bool>.broadcast();
  @override
  bool get isOnline => true;
  @override
  Stream<bool> get onlineStream => _c.stream;
  @override
  Future<void> refresh() async {}
  @override
  void dispose() => _c.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Auth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

class _AuthedUser extends AuthController {
  @override
  Future<UserEntity?> build() async =>
      const UserEntity(id: 'u_client', username: 'client');
}

class _HangingTrtcRemote implements TrtcRemoteDataSource {
  int tokenCalls = 0;
  @override
  Future<TrtcCredentials> fetchToken({
    required String roomId,
    String role = 'audience',
    String? userId,
  }) {
    tokenCalls++;
    return Completer<TrtcCredentials>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _session = PsychicSessionEntity(
  sessionId: 'sess_poll',
  psychic: PsychicEntity(id: 'teller_p', name: 'Poll Falcı', isOnline: true),
  durationMinutes: 10,
  totalJeton: 100,
  isClient: true,
);

class _Run {
  _Run(this.container, this.repo, this.sse);
  final ProviderContainer container;
  final _ProbeRepo repo;
  final _FakeSse sse;
  PsychicVideoState get state =>
      container.read(psychicVideoControllerProvider(_session));
}

_Run _open(_ProbeRepo repo, _FakeSse sse, {Override? extra, bool authed = false}) {
  final container = ProviderContainer(overrides: [
    livePsychicsRepositoryProvider.overrideWithValue(repo),
    psychicRoomSseServiceProvider.overrideWithValue(sse),
    connectivityServiceProvider.overrideWithValue(_FakeConn()),
    authControllerProvider.overrideWith(authed ? _AuthedUser.new : _Auth.new),
    ?extra,
  ]);
  container.listen(psychicVideoControllerProvider(_session), (_, _) {});
  return _Run(container, repo, sse);
}

/// Sanal zamanı küçük adımlarla ilerletir; en uzun tek adımın GERÇEK (duvar
/// saati) süresini döndürür — ana isolate'i bloklayan CPU işi varsa büyür.
Future<int> _advance(WidgetTester tester, Duration total) async {
  var worst = 0;
  final sw = Stopwatch();
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 100)) {
    sw.reset();
    sw.start();
    await tester.pump(const Duration(milliseconds: 100));
    sw.stop();
    if (sw.elapsedMilliseconds > worst) worst = sw.elapsedMilliseconds;
  }
  return worst;
}

void _metric(String scenario, _ProbeRepo r, _FakeSse s, int worstPumpMs,
    {String extra = ''}) {
  debugPrint(
    'METRIC $scenario | istek=${r.total} | maxEşzamanlı=${r.worstConcurrency} '
    '| detay=${r.calls} | maxUçuşta=${r.maxInFlight} | sseConnect=${s.connectCalls} '
    '| enUzunAdımMs=$worstPumpMs $extra',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Bekleyen sahte gecikmeleri (Future.delayed) boşaltır; test artığı olmasın.
  Future<void> drain(WidgetTester t, Duration d) => t.pump(d);

  testWidgets('S1: yavaş ağ (5 sn gecikme) — 12 sn bağlantı fazı', (tester) async {
    final repo = _ProbeRepo()
      ..mode = _Mode.slow
      ..latency = const Duration(seconds: 5);
    final sse = _FakeSse();
    final run = _open(repo, sse);
    final worst = await _advance(tester, const Duration(seconds: 12));
    _metric('yavaş-ağ', repo, sse, worst);
    for (final e in repo.maxInFlight.entries) {
      expect(e.value, lessThanOrEqualTo(1),
          reason: '${e.key}: yoklama aynı anda birden fazla istek taşıyor');
    }
    run.container.dispose();
    await drain(tester, const Duration(seconds: 6));
  });

  testWidgets('S2: ağ kesik (her istek hata) — çökme yok, istek fırtınası yok',
      (tester) async {
    final repo = _ProbeRepo()..mode = _Mode.fail;
    final sse = _FakeSse();
    final run = _open(repo, sse);
    final worst = await _advance(tester, const Duration(seconds: 10));
    _metric('ağ-kesik', repo, sse, worst);
    expect(run.state.leaving, isFalse);
    expect(repo.worstConcurrency, lessThanOrEqualTo(1));
    run.container.dispose();
    await drain(tester, const Duration(seconds: 1));
  });

  testWidgets('S3: sunucu hiç yanıt vermiyor — 30 sn, eşzamanlılık sınırlı',
      (tester) async {
    final repo = _ProbeRepo()..mode = _Mode.hang;
    final sse = _FakeSse();
    final run = _open(repo, sse);
    final worst = await _advance(tester, const Duration(seconds: 30));
    _metric('api-hang', repo, sse, worst);
    expect(repo.worstConcurrency, lessThanOrEqualTo(1),
        reason: 'yanıtsız sunucuda istek birikiyor');
    expect(repo.total, lessThanOrEqualTo(4),
        reason: 'yanıtsız sunucuya istek yağıyor');
    run.container.dispose();
    await drain(tester, const Duration(seconds: 1));
  });

  testWidgets('S4: 10 kez gir/çık — dispose sonrası hiç istek sızmaz',
      (tester) async {
    final repo = _ProbeRepo();
    final sse = _FakeSse();
    for (var i = 0; i < 10; i++) {
      final run = _open(repo, sse);
      await _advance(tester, const Duration(seconds: 3));
      run.container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    }
    final after = repo.total;
    final worst = await _advance(tester, const Duration(seconds: 30));
    _metric('10x-gir-çık', repo, sse, worst, extra: '| sızan=${repo.total - after}');
    expect(repo.total, after,
        reason: 'dispose edilmiş controller hâlâ istek atıyor (timer sızıntısı)');
    expect(sse.disconnectedFor.every((id) => id == 'sess_poll'), isTrue,
        reason: 'dispose, yalnız KENDİ seansının SSE bağlantısını kapatmalı');
    expect(sse.disconnectCalls, 10);
    // Tek bir zamanlayıcı kümesi: 3 sn'de ≤ 5 sinyal yoklaması (900 ms + ilk).
    expect((repo.calls['fetchRoomSignals'] ?? 0) / 10, lessThanOrEqualTo(5.0),
        reason: 'aynı zamanlayıcı birden fazla kez başlatılmış');
  });

  testWidgets('S5: SSE geç bağlanıyor — tek bağlantı, sohbet+oda yedeği sürer',
      (tester) async {
    final repo = _ProbeRepo();
    final sse = _FakeSse()..delay = const Duration(seconds: 20);
    final run = _open(repo, sse);
    final worst = await _advance(tester, const Duration(seconds: 12));
    final up = run.state.sseConnected;
    _metric('sse-geç', repo, sse, worst, extra: '| sseConnected=$up');
    expect(sse.connectCalls, 1, reason: 'yinelenen SSE bağlantısı');
    expect(up, isFalse);
    expect(repo.calls['fetchRoom'] ?? 0, greaterThan(0));
    expect(repo.calls['fetchMessages'] ?? 0, greaterThan(0),
        reason: 'SSE gelene kadar sohbet yoklama yedeği çalışmalı');
    run.container.dispose();
    await drain(tester, const Duration(seconds: 21));
  });

  testWidgets('S6: TRTC token yanıtsız — 20 sn sonra hata, sonsuz bekleme yok; '
      'SSE ve sohbet join\'i beklemez', (tester) async {
    final repo = _ProbeRepo();
    final sse = _FakeSse();
    final remote = _HangingTrtcRemote();
    final run = _open(
      repo,
      sse,
      authed: true,
      extra: trtcRemoteProvider.overrideWithValue(remote),
    );
    final worst = await _advance(tester, const Duration(seconds: 10));
    final sseConnectedWhileJoining = sse.connectCalls;
    final chatWhileJoining = repo.calls['fetchMessages'] ?? 0;
    final errBefore = run.state.rtcError;
    await _advance(tester, const Duration(seconds: 15));
    _metric('trtc-geç', repo, sse, worst,
        extra: '| tokenCalls=${remote.tokenCalls} '
            'join sırasında sseConnect=$sseConnectedWhileJoining '
            'chat=$chatWhileJoining rtcError(10s)=$errBefore '
            'rtcError(25s)=${run.state.rtcError} faz=${run.state.phase.name}');
    expect(remote.tokenCalls, 1, reason: 'yinelenen TRTC join/token isteği');
    expect(sseConnectedWhileJoining, 1,
        reason: 'SSE, TRTC join bitmeden bağlanmalı');
    expect(chatWhileJoining, greaterThan(0),
        reason: 'sohbet yoklaması TRTC join bitmeden çalışmalı');
    expect(run.state.rtcError, isNotNull,
        reason: 'TRTC token zaman aşımından sonra hata gösterilmeli');
    run.container.dispose();
    await drain(tester, const Duration(seconds: 1));
  });

  testWidgets('S7: eski seansın disconnect çağrısı yeni seansı kapatmaz (mantık)',
      (tester) async {
    expect(
      PsychicRoomSseService.isStaleDisconnect(
          activeSessionId: 'B', requested: 'A'),
      isTrue,
    );
    expect(
      PsychicRoomSseService.isStaleDisconnect(
          activeSessionId: 'B', requested: 'B'),
      isFalse,
    );
    expect(
      PsychicRoomSseService.isStaleDisconnect(
          activeSessionId: null, requested: 'A'),
      isFalse,
    );
    expect(
      PsychicRoomSseService.isStaleDisconnect(
          activeSessionId: 'B', requested: null),
      isFalse,
    );
  });
}
