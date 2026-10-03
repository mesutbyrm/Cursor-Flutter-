import 'dart:async';

import '../../domain/pk/live_pk_local_score.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/bot_account_guard.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/bot_account_provider.dart';
import '../../domain/pk/live_pk_event_dedup.dart';
import '../../domain/pk/live_pk_ingest.dart';
import '../../domain/pk/pk_action_error.dart';
import 'live_pk_score_burst_provider.dart';
import '../../domain/pk/live_pk_broadcast_stage.dart';
import '../../domain/pk/live_pk_refresh_stale_guard.dart';
import '../../domain/pk/pk_status_helper.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import 'live_pk_action_lock_provider.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import 'pk_session_phase_provider.dart';
import 'live_room_providers.dart';
import '../navigation/live_pk_home_transition_bridge.dart';

class LiveVideoPkState {
  const LiveVideoPkState({
    this.battle,
    this.unifiedMatchId,
    this.loading = false,
    this.error,
  });

  final Map<String, dynamic>? battle;
  final String? unifiedMatchId;
  final bool loading;
  final String? error;

  String get status => battle?['status']?.toString() ?? '';

  bool get isUnified => battle?['unifiedPk'] == true;

  bool get isOpponent => battle?['isOpponent'] == true;

  int get leftScore {
    final v = battle?['score1'] ?? battle?['leftScore'];
    return v is num ? v.toInt() : 0;
  }

  int get rightScore {
    final v = battle?['score2'] ?? battle?['rightScore'];
    return v is num ? v.toInt() : 0;
  }

  LiveVideoPkState copyWith({
    Map<String, dynamic>? battle,
    String? unifiedMatchId,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearBattle = false,
    bool clearUnifiedMatchId = false,
  }) {
    return LiveVideoPkState(
      battle: clearBattle ? null : (battle ?? this.battle),
      unifiedMatchId:
          clearUnifiedMatchId ? null : (unifiedMatchId ?? this.unifiedMatchId),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

int pkScoreInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class LiveVideoPkNotifier extends AutoDisposeFamilyNotifier<LiveVideoPkState, String> {
  Timer? _poll;
  Timer? _endedCleanup;
  Timer? _endsAtRefresh;
  String? _lastIngestFingerprint;
  final _eventDedup = LivePkEventDedup();
  var _refreshInFlight = false;
  DateTime? _lastRemoteBattleIngestAt;

  /// Kapatılan (çıkış yapılan / bitmiş) battle kimlikleri — gecikmeli SSE/REST
  /// yanıtı ekranı yeniden PK'ya döndürmesin.
  final _closedBattleIds = <String>{};

  static String _battleIdOf(Map<String, dynamic>? b) =>
      (b?['id'] ?? b?['battleId'] ?? b?['pkBattleId'] ?? '').toString().trim();

  bool _isClosed(Map<String, dynamic>? b) {
    final id = _battleIdOf(b);
    return id.isNotEmpty && _closedBattleIds.contains(id);
  }

  void _markClosed(String? id) {
    final v = id?.trim() ?? '';
    if (v.isEmpty) return;
    _closedBattleIds.add(v);
    if (_closedBattleIds.length > 32) {
      _closedBattleIds.remove(_closedBattleIds.first);
    }
  }

  bool _shouldRetainBattleOnEmptyRefresh() {
    return shouldRetainPkBattleOnEmptyRefresh(
      battle: state.battle,
      status: state.status,
    );
  }

  @override
  LiveVideoPkState build(String streamId) {
    ref.onDispose(() {
      _poll?.cancel();
      _endedCleanup?.cancel();
      _endsAtRefresh?.cancel();
    });
    Future.microtask(() => refresh());
    return const LiveVideoPkState();
  }

  void _startPolling() {
    _poll?.cancel();
    final sse = ref.read(liveRoomProvider(arg)).sseConnected;
    final interval =
        sse ? const Duration(seconds: 10) : const Duration(seconds: 5);
    _poll = Timer.periodic(interval, (_) {
      if (state.battle == null ||
          state.status == 'completed' ||
          state.status == 'ended') {
        _poll?.cancel();
        return;
      }
      final last = _lastRemoteBattleIngestAt;
      if (last != null &&
          DateTime.now().difference(last) < const Duration(seconds: 12)) {
        return;
      }
      refresh();
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
    _endsAtRefresh?.cancel();
    _endsAtRefresh = null;
  }

  /// Sayaç bittiği anda sunucudan durum iste (15 sn yoklamayı bekleme);
  /// sunucu henüz kapatmadıysa kısa aralıkla birkaç kez tekrar dener.
  void _scheduleEndsAtRefresh(Map<String, dynamic> battle, {int attempt = 0}) {
    _endsAtRefresh?.cancel();
    final endsAt = DateTime.tryParse(battle['endsAt']?.toString() ?? '');
    if (endsAt == null || attempt > 5) return;
    var wait = endsAt.difference(DateTime.now().toUtc()) +
        const Duration(milliseconds: 1500);
    if (wait.isNegative) wait = Duration(seconds: 2 + attempt * 2);
    _endsAtRefresh = Timer(wait, () async {
      await refresh();
      final st = state.status;
      if (state.battle != null && isLivePkActiveStatus(st)) {
        _scheduleEndsAtRefresh(state.battle!, attempt: attempt + 1);
      }
    });
  }

  Future<void> refresh() async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    try {
    // Canlı 1v1 PK — GET stream battle (davet: LivePkInviteListener + SSE).
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      final remote = await api.fetchStreamBattle(arg);
      if (remote != null) {
        final fresh = pkBattleRemoteToBattleMap(remote, myStreamId: arg);
        if (_isClosed(fresh) ||
            (state.battle == null &&
                livePkBattleFinished(status: remote.status, battle: fresh))) {
          _stopPolling();
          return;
        }
        final map = _mergeBattleMap(
          fresh,
          previous: state.battle,
        );
        final finished = remote.isEnded ||
            livePkBattleFinished(status: remote.status, battle: map);
        state = state.copyWith(
          battle: map,
          unifiedMatchId: remote.effectiveId,
          clearError: true,
        );
        if (isLivePkActiveStatus(remote.status) && !finished) {
          _startPolling();
          _scheduleEndsAtRefresh(map);
        } else {
          _stopPolling();
          if (finished) {
            _scheduleEndedCleanup(remote.effectiveId);
          }
        }
        return;
      }
    } on ApiException catch (e) {
      state = state.copyWith(error: ApiException.userMessage(e));
      // Sunucu battle'ın yokluğunu açıkça bildirmedikçe hata bir bilgi
      // yokluğudur; mevcut battle korunur ve polling sürer ki bağlantı
      // dönünce kendiliğinden toparlasın. 404/410'da eski akışa (guard +
      // temizlik) devam edilir.
      if (!pkRefreshErrorMeansBattleGone(e.statusCode)) {
        return;
      }
    } catch (e) {
      state = state.copyWith(error: ApiException.userMessage(e));
      return;
    }

      _stopPolling();
      if (_shouldRetainBattleOnEmptyRefresh()) {
        return;
      }
      state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
    } finally {
      _refreshInFlight = false;
    }
  }

  /// İzleyici/yayıncı beğenisi sonrası skoru ANINDA yerelde artırır (iyimser).
  ///
  /// [side]: `'left'` (challenger / score1) veya `'right'` (rakip / score2).
  /// Sunucu yanıtı / SSE mutlak değer getirince [applyScoreSnapshot] yalnız
  /// artırır, [applyRemoteBattle] ise sunucu değerini esas alır; böylece iyimser
  /// artış çift sayıma yol açmaz.
  void applyLocalScoreDelta({required String side, required int amount}) {
    final b = state.battle;
    if (b == null || amount <= 0) return;
    if (!isLivePkActiveStatus(state.status) ||
        livePkBattleFinished(status: state.status, battle: b)) {
      return;
    }
    state = state.copyWith(
      battle: battleWithLocalScore(b, side: side, amount: amount),
    );
  }

  /// Bu yayının PK'daki tarafı: challenger (host) yayını `left`, aksi `right`.
  String mySideInBattle() {
    final b = state.battle;
    return b == null ? 'left' : pkSideForStream(b, arg);
  }

  /// Hediye / beğeni sonrası — yakın SSE ingest varsa REST yoklamayı atla.
  Future<void> refreshScoresIfStale({
    Duration sseFreshWindow = const Duration(seconds: 8),
  }) async {
    final last = _lastRemoteBattleIngestAt;
    if (last != null &&
        DateTime.now().difference(last) < sseFreshWindow) {
      return;
    }
    await refresh();
  }

  Map<String, dynamic> _mergeBattleMap(
    Map<String, dynamic> incoming,
    {Map<String, dynamic>? previous,
  }) {
    if (previous == null) return incoming;
    final out = Map<String, dynamic>.from(previous);
    for (final e in incoming.entries) {
      final v = e.value;
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      out[e.key] = v;
    }
    for (final key in [
      'liveStreamId',
      'hostStreamId',
      'opponentLiveStreamId',
      'opponentStreamId',
      'endsAt',
      'startedAt',
    ]) {
      final inc = incoming[key]?.toString().trim() ?? '';
      if (inc.isEmpty) continue;
      out[key] = incoming[key];
    }
    _ensurePkEndsAt(out);
    _guardPrematureEndedStatus(out, previous: previous);
    return out;
  }

  void _guardPrematureEndedStatus(
    Map<String, dynamic> merged, {
    Map<String, dynamic>? previous,
  }) {
    final incStatus = merged['status']?.toString();
    if (isLivePkOutcomeOnlyStatus(incStatus) &&
        !livePkBattleFinished(status: incStatus, battle: merged)) {
      merged['status'] =
          previous?['status']?.toString().trim().isNotEmpty == true
              ? previous!['status']
              : 'active';
      return;
    }
    if (previous == null) return;
    final prevStatus = previous['status']?.toString();
    final prevActive = isLivePkActiveStatus(prevStatus) ||
        isLivePkStartingStatus(prevStatus) ||
        isLivePkPausedStatus(prevStatus);
    if (!prevActive) return;
    if (!livePkBattleFinished(status: incStatus, battle: merged)) return;
    final endsAt =
        DateTime.tryParse(merged['endsAt']?.toString() ?? '')?.toUtc();
    if (endsAt != null && DateTime.now().toUtc().isBefore(endsAt)) {
      merged['status'] = previous['status'];
    }
  }

  void _ensurePkEndsAt(Map<String, dynamic> battle) {
    final endsRaw = battle['endsAt']?.toString().trim() ?? '';
    if (endsRaw.isNotEmpty && DateTime.tryParse(endsRaw) != null) return;
    final started = DateTime.tryParse(battle['startedAt']?.toString() ?? '');
    if (started == null) return;
    final dur = int.tryParse(
          '${battle['durationSeconds'] ?? battle['duration'] ?? 180}',
        ) ??
        180;
    battle['endsAt'] =
        started.toUtc().add(Duration(seconds: dur)).toIso8601String();
  }

  /// Kabul sonrası veya SSE'den — ana backend PK durumunu yeniler.
  Future<void> ingestRemoteBattle([String? battleId]) async {
    await refresh();
  }

  void applyRemoteBattle(Map<String, dynamic> battle) {
    if (_isClosed(battle)) return;
    if (!_eventDedup.shouldProcess(battle)) {
      return;
    }
    final fp = livePkBattleIngestFingerprint(battle);
    if (fp.isNotEmpty && fp == _lastIngestFingerprint) {
      return;
    }
    _lastIngestFingerprint = fp;
    _lastRemoteBattleIngestAt = DateTime.now();

    final status = battle['status']?.toString() ?? '';
    // Pending davet split ekranı açmaz; yalnızca kabul sonrası aktif senkron.
    final merged = _mergeBattleMap(battle, previous: state.battle);
    if (isPkInvitePendingStatus(status)) {
      state = state.copyWith(battle: merged, clearError: true);
      syncLivePkHomeTransitionFromBattle(ref, battle: merged, streamId: arg);
      _stopPolling();
      return;
    }
    final mergedStatus = merged['status']?.toString() ?? '';
    final stillRunning = isLivePkActiveStatus(mergedStatus) ||
        isLivePkStartingStatus(mergedStatus) ||
        isLivePkPausedStatus(mergedStatus) ||
        (isLivePkOutcomeOnlyStatus(mergedStatus) &&
            !livePkBattleFinished(status: mergedStatus, battle: merged));
    if (!stillRunning) {
      state = state.copyWith(battle: merged, clearError: true);
      syncLivePkHomeTransitionFromBattle(ref, battle: merged, streamId: arg);
      _stopPolling();
      if (livePkBattleFinished(status: mergedStatus, battle: merged)) {
        _scheduleEndedCleanup(merged['id']?.toString() ?? '');
      }
      return;
    }
    final matchId = merged['id']?.toString() ?? merged['battleId']?.toString();
    state = state.copyWith(
      battle: merged,
      unifiedMatchId: matchId ?? state.unifiedMatchId,
      clearError: true,
    );
    syncLivePkHomeTransitionFromBattle(ref, battle: merged, streamId: arg);
    if (state.isUnified && matchId != null && matchId.isNotEmpty) {
      _stopPolling();
    } else {
      _startPolling();
    }
  }

  void _scheduleEndedCleanup(String battleId) {
    final bid = battleId.trim();
    if (bid.isEmpty) return;
    _endedCleanup?.cancel();
    _endedCleanup = Timer(const Duration(seconds: 4), () {
      dismissEndedOverlay(expectedBattleId: bid);
    });
  }

  /// Koşulsuz çıkış — PK bittiğinde host "PK'yi Kapat"a basınca split ekranı
  /// her durumda temizlenir ve normal yayına dönülür (takılı kalmaya son).
  void forceExitPk() {
    _markClosed(_battleIdOf(state.battle));
    _markClosed(state.unifiedMatchId);
    _stopPolling();
    _endedCleanup?.cancel();
    _eventDedup.clear();
    _lastIngestFingerprint = null;
    ref.read(livePkScoreBurstProvider(arg).notifier).reset();
    state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
    ref.read(livePkHomeTransitionProvider.notifier).reset();
  }

  /// PK sonuç ekranından sonra split'i kapatır (sunucu zaten `ended` döndü).
  void dismissEndedOverlay({String? expectedBattleId}) {
    final currentId = state.battle?['id']?.toString() ?? '';
    if (!livePkBattleFinished(status: state.status, battle: state.battle)) {
      return;
    }
    if (expectedBattleId != null &&
        expectedBattleId.trim().isNotEmpty &&
        currentId != expectedBattleId.trim()) {
      return;
    }
    _markClosed(currentId);
    _endedCleanup?.cancel();
    _eventDedup.clear();
    _lastIngestFingerprint = null;
    ref.read(livePkScoreBurstProvider(arg).notifier).reset();
    state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
    ref.read(livePkHomeTransitionProvider.notifier).reset();
  }

  /// "PK bitir": ekran HEMEN tekli yayına döner; sunucu çağrısı arka planda
  /// yapılır (ağ gecikmesi kullanıcıyı PK ekranında bekletmez).
  /// Dönen değer: sunucu bitirmeyi kabul etti mi (zaten bitmiş = true).
  Future<bool> endAndExit() async {
    final battleId = state.unifiedMatchId ?? _battleIdOf(state.battle);
    forceExitPk();
    if (battleId.isEmpty) return true;
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      await api.streamPkAction(
        streamId: arg,
        action: 'end',
        battleId: battleId,
      );
      api.invalidatePkPollCaches();
      return true;
    } catch (e) {
      return pkActionErrorMeansAlreadySettled(e);
    }
  }

  /// Skor bildirimi (hediye/destek yanıtı) — mutlak değerler, yalnız artar.
  void applyScoreSnapshot({required int score1, required int score2}) {
    final b = state.battle;
    if (b == null || livePkBattleFinished(status: state.status, battle: b)) {
      return;
    }
    final cur1 = pkScoreInt(b['score1'] ?? b['leftScore']);
    final cur2 = pkScoreInt(b['score2'] ?? b['rightScore']);
    if (score1 < cur1 && score2 < cur2) return;
    final next = Map<String, dynamic>.from(b)
      ..['score1'] = score1 > cur1 ? score1 : cur1
      ..['score2'] = score2 > cur2 ? score2 : cur2
      ..['leftScore'] = score1 > cur1 ? score1 : cur1
      ..['rightScore'] = score2 > cur2 ? score2 : cur2
      ..['challengerScore'] = score1 > cur1 ? score1 : cur1
      ..['opponentScore'] = score2 > cur2 ? score2 : cur2;
    _lastRemoteBattleIngestAt = DateTime.now();
    state = state.copyWith(battle: next);
  }

  Future<void> create({String? opponentStreamId, String? targetStreamId}) async {
    if (ref.read(isBotAccountProvider)) {
      state = state.copyWith(
        loading: false,
        error: BotAccountGuard.blockedMessage('PK başlatma'),
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    final opponent = targetStreamId ?? opponentStreamId;
    try {
      if (opponent != null && opponent.isNotEmpty) {
        final api = ref.read(pkBattleRemoteDataSourceProvider);
        final remote = await api.streamPkAction(
          streamId: arg,
          action: 'create',
          opponentStreamId: opponent,
          duration: 180,
        );
        if (remote != null) {
          ref.read(pkBattleRemoteDataSourceProvider).invalidatePkPollCaches();
          state = state.copyWith(
            battle: pkBattleRemoteToBattleMap(remote, myStreamId: arg),
            unifiedMatchId: remote.effectiveId,
            loading: false,
          );
          return;
        }
      }
      state = state.copyWith(
        loading: false,
        error: 'PK oluşturulamadı. Sunucu yanıt vermedi; bağlantınızı kontrol edin.',
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    }
  }

  Future<void> accept() => _action('accept');
  Future<void> reject() => _action('reject');
  Future<void> cancel() => _action('cancel');
  Future<void> end() => _action('end');

  Future<void> _action(String action) async {
    final api = ref.read(pkBattleRemoteDataSourceProvider);
    final battleId = state.unifiedMatchId ?? state.battle?['id']?.toString();
    if (battleId == null || battleId.isEmpty) {
      ref.read(pkSessionPhaseProvider.notifier).reset();
      state = state.copyWith(loading: false, error: 'PK bulunamadı');
      return;
    }
    final lock = ref.read(livePkActionLockProvider.notifier);
    if (!lock.tryAcquire(battleId, action)) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      PkBattleRemote? remote;
      switch (action) {
        case 'accept':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'accept',
            battleId: battleId,
          );
          break;
        case 'reject':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'reject',
            battleId: battleId,
          );
          break;
        case 'cancel':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'cancel',
            battleId: battleId,
          );
          break;
        case 'end':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'end',
            battleId: battleId,
          );
          break;
      }
      if (remote != null) {
        ref.read(pkBattleRemoteDataSourceProvider).invalidatePkPollCaches();
        state = state.copyWith(
          battle: pkBattleRemoteToBattleMap(remote, myStreamId: arg),
          unifiedMatchId: remote.effectiveId,
          loading: false,
        );
        if (remote.isEnded) {
          _stopPolling();
          _scheduleEndedCleanup(remote.effectiveId);
        }
        return;
      }
      ref.read(pkSessionPhaseProvider.notifier).reset();
      state = state.copyWith(loading: false, error: 'PK işlemi başarısız');
    } catch (e) {
      ref.read(pkSessionPhaseProvider.notifier).reset();
      // Süre dolduğunda sunucu maçı kendisi bitiriyor; kullanıcı bu sırada
      // "PK'yi Bitir"e basarsa "PK zaten bitmiş" dönüyordu. İstenen sonuç
      // zaten sağlandığı için bu bir hata değil — sessizce senkron ol.
      if (pkActionErrorMeansAlreadySettled(e)) {
        state = state.copyWith(loading: false, clearError: true);
        await refresh();
        return;
      }
      // Ham `'$e'` kullanıcıya "ApiException(400): ..." gösteriyordu.
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    } finally {
      lock.release(battleId, action);
    }
  }
}

final liveVideoPkProvider = NotifierProvider.autoDispose
    .family<LiveVideoPkNotifier, LiveVideoPkState, String>(
  LiveVideoPkNotifier.new,
);
