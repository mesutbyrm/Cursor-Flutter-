import 'dart:async';

/// Canlı fal video oturumu — Tencent TRTC.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/config/env.dart';
import 'package:canlifal_social/core/diagnostics/cf_diag.dart';
import 'package:canlifal_social/core/diagnostics/cf_diagnostic_logger.dart';
import 'package:canlifal_social/core/diagnostics/cf_diagnostic_session_monitor.dart';
import 'package:canlifal_social/core/diagnostics/cf_resource_tracker.dart';
import 'package:canlifal_social/core/diagnostics/cf_trace.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/dio_provider.dart';
import 'package:canlifal_social/core/network/live_debug_log.dart';
import 'package:canlifal_social/core/network/psychic_event_log.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_beauty_provider.dart';
import 'package:canlifal_social/features/trtc/data/trtc_session_store.dart';
import 'package:canlifal_social/features/trtc/presentation/providers/trtc_providers.dart';
import 'package:canlifal_social/features/trtc/presentation/trtc_room_manager.dart';
import 'package:canlifal_social/core/network/connectivity/connectivity_service.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_session_phase.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_trtc_connection.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_timer_handshake.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_trtc_identity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_extend_sheet.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_tip_sheet.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_room_sse_service.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_peer_left_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_ended_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/diagnostics/psychic_rtc_session_report.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import '../../../../core/diagnostics/cf_auto_detect.dart';

enum PsychicRtcBackend { none, trtc }

class PsychicVideoState {
  const PsychicVideoState({
    this.phase = PsychicSessionPhase.joining,
    this.rtcReady = false,
    this.rtcError,
    this.rtcBackend = PsychicRtcBackend.none,
    this.messages = const [],
    this.remaining = Duration.zero,
    this.timerStarted = false,
    this.waitingForTimer = false,
    this.leaving = false,
    this.sendingChat = false,
    this.room,
    this.tipThankYouAmount,
    this.tipReceivedAmount,
    this.tipReceivedFrom,
    this.sessionTipsTotal = 0,
    this.sseConnected = false,
    this.localPreviewKey = 0,
    this.timeUpPending = false,
    this.lowTimeWarningPending = false,
    this.sseFailed = false,
    this.remoteCamera = const {},
    this.remoteMicrophone = const {},
    this.timerStartRequestSent = false,
    this.timerStartPrompt = false,
  });

  final PsychicSessionPhase phase;
  final bool rtcReady;
  final String? rtcError;
  final PsychicRtcBackend rtcBackend;
  final List<PsychicChatMessage> messages;
  final Duration remaining;
  final bool timerStarted;
  final bool waitingForTimer;
  final bool leaving;
  final bool sendingChat;
  final PsychicRoomEntity? room;
  final int? tipThankYouAmount;
  final int? tipReceivedAmount;
  final String? tipReceivedFrom;
  final int sessionTipsTotal;
  final bool sseConnected;
  final int localPreviewKey;
  final bool timeUpPending;
  final bool lowTimeWarningPending;
  final bool sseFailed;
  /// Uzak katılımcı kamera durumu — userId → açık mı (yerel kameradan bağımsız).
  final Map<String, bool> remoteCamera;
  /// Uzak katılımcı mikrofon durumu — userId → açık mı (yerel mikrofondan bağımsız).
  final Map<String, bool> remoteMicrophone;
  /// Falcı: danışana süre başlatma isteği gönderildi mi (onay bekleniyor).
  final bool timerStartRequestSent;
  /// Danışan: falcının süre başlatma isteği geldi — onay istemi gösterilmeli.
  final bool timerStartPrompt;

  String get timerLabel {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  PsychicVideoState copyWith({
    PsychicSessionPhase? phase,
    bool? rtcReady,
    String? rtcError,
    PsychicRtcBackend? rtcBackend,
    bool clearRtcError = false,
    List<PsychicChatMessage>? messages,
    Duration? remaining,
    bool? timerStarted,
    bool? waitingForTimer,
    bool? leaving,
    bool? sendingChat,
    PsychicRoomEntity? room,
    int? tipThankYouAmount,
    bool clearTipThankYou = false,
    int? tipReceivedAmount,
    String? tipReceivedFrom,
    bool clearTipReceived = false,
    int? sessionTipsTotal,
    bool? sseConnected,
    int? localPreviewKey,
    bool? timeUpPending,
    bool? lowTimeWarningPending,
    bool? sseFailed,
    Map<String, bool>? remoteCamera,
    Map<String, bool>? remoteMicrophone,
    bool? timerStartRequestSent,
    bool? timerStartPrompt,
  }) {
    return PsychicVideoState(
      phase: phase ?? this.phase,
      rtcReady: rtcReady ?? this.rtcReady,
      rtcError: clearRtcError ? null : (rtcError ?? this.rtcError),
      rtcBackend: rtcBackend ?? this.rtcBackend,
      messages: messages ?? this.messages,
      remaining: remaining ?? this.remaining,
      timerStarted: timerStarted ?? this.timerStarted,
      waitingForTimer: waitingForTimer ?? this.waitingForTimer,
      leaving: leaving ?? this.leaving,
      sendingChat: sendingChat ?? this.sendingChat,
      room: room ?? this.room,
      tipThankYouAmount:
          clearTipThankYou ? null : (tipThankYouAmount ?? this.tipThankYouAmount),
      tipReceivedAmount: clearTipReceived
          ? null
          : (tipReceivedAmount ?? this.tipReceivedAmount),
      tipReceivedFrom:
          clearTipReceived ? null : (tipReceivedFrom ?? this.tipReceivedFrom),
      sessionTipsTotal: sessionTipsTotal ?? this.sessionTipsTotal,
      sseConnected: sseConnected ?? this.sseConnected,
      localPreviewKey: localPreviewKey ?? this.localPreviewKey,
      timeUpPending: timeUpPending ?? this.timeUpPending,
      lowTimeWarningPending:
          lowTimeWarningPending ?? this.lowTimeWarningPending,
      sseFailed: sseFailed ?? this.sseFailed,
      remoteCamera: remoteCamera ?? this.remoteCamera,
      remoteMicrophone: remoteMicrophone ?? this.remoteMicrophone,
      timerStartRequestSent:
          timerStartRequestSent ?? this.timerStartRequestSent,
      timerStartPrompt: timerStartPrompt ?? this.timerStartPrompt,
    );
  }
}

class PsychicVideoController extends StateNotifier<PsychicVideoState> {
  PsychicVideoController(this.ref, PsychicSessionEntity session)
      : session = session,
        super(PsychicVideoState(remaining: Duration(minutes: session.durationMinutes))) {
    _trtc = ref.read(trtcRoomManagerProvider);
    // dispose() içinde ref kullanılmasın diye servis baştan alınır.
    _roomSse = ref.read(psychicRoomSseServiceProvider);
    _trtcConn.sessionId = session.sessionId;
    _watchNetwork();
    CfDiagnosticSessionMonitor.transition(
      type: 'LIVE_FORTUNE',
      sessionKey: session.sessionId,
      state: 'CREATE',
    );
    _bootstrap();
  }

  final Ref ref;
  PsychicSessionEntity session;

  late final TrtcRoomManager _trtc;
  late final PsychicRoomSseService _roomSse;
  final _trtcConn = PsychicTrtcConnection();
  final _remoteBind = PsychicTrtcListenerBind();
  final _seenChatIds = <String>{};
  String? _lastChatAfter;
  Timer? _tick;
  Timer? _chatPoll;
  Timer? _ping;
  Timer? _roomPoll;
  Timer? _signalPoll;

  /// Yoklama zamanlayıcıları (0,9 sn / 2 sn / 3 sn) yavaş ağda eski istek
  /// bitmeden yenisini başlatıp istekleri biriktiriyordu; her yoklama türü
  /// aynı anda tek istekle sınırlandı.
  final _roomSync = CfSingleFlight<bool>();
  final _signalsFlight = CfSingleFlight<void>();
  final _chatFlight = CfSingleFlight<void>();
  final _pingFlight = CfSingleFlight<void>();
  DateTime? _lastRoomSyncAt;
  DateTime? _lastTimerStartRequestAt;
  var _disposed = false;
  var _remoteEndHandled = false;
  final _seenSignalIds = <String>{};
  final _seenTipEventIds = <String>{};
  Timer? _sseAutoRetryTimer;
  var _sseAutoRetryCount = 0;
  static const _maxSseAutoRetry = 3;
  Timer? _remoteVideoWatchdog;
  var _resubscribeAttempts = 0;
  static const _maxResubscribeAttempts = 2;
  static const _remoteVideoWatchdogInterval = Duration(seconds: 5);
  Timer? _tipThankYouDismissTimer;
  Timer? _tipReceivedDismissTimer;
  static const _tipOverlayDismissDuration = Duration(seconds: 3);
  DateTime? _lastTipReceivedPopupAt;
  StreamSubscription<bool>? _onlineSub;
  final _diagTimerResourceIds = <String, String>{};
  CancelToken? _roomSyncHttpCancel;
  CancelToken? _signalsHttpCancel;

  VoidCallback? _remoteVideoListener;
  VoidCallback? _remoteAudioListener;
  VoidCallback? _remotePresenceListener;

  void _setPhase(PsychicSessionPhase next) {
    final from = state.phase;
    final allowed = PsychicSessionPhaseGuard.transition(from, next);
    if (allowed == null) return;
    PsychicEventLog.phase(from.name, allowed.name, sessionId: session.sessionId);
    state = state.copyWith(phase: allowed);
    CfDiagnosticSessionMonitor.transition(
      type: 'LIVE_FORTUNE',
      sessionKey: session.sessionId,
      state: _sessionStateForPhase(allowed),
      metadata: {'from': from.name, 'to': allowed.name},
    );
  }

  static String _sessionStateForPhase(PsychicSessionPhase phase) =>
      switch (phase) {
        PsychicSessionPhase.joining => 'CONNECTING',
        PsychicSessionPhase.connected => 'CONNECTED',
        PsychicSessionPhase.reconnecting => 'CONNECTING',
        PsychicSessionPhase.ending => 'ENDING',
        PsychicSessionPhase.ended => 'ENDED',
        PsychicSessionPhase.error => 'ERROR',
        _ => 'ACTIVE',
      };

  Timer _periodic(
    Duration interval,
    void Function(Timer timer) onTick, {
    required String label,
  }) {
    if (!CfDiagnosticLogger.active) {
      return Timer.periodic(interval, onTick);
    }
    final tracked = CfResourceTracker.periodic(
      interval,
      onTick,
      module: 'live_fortune',
      label: label,
    );
    _diagTimerResourceIds[label] = tracked.resourceId;
    return tracked.timer;
  }

  void _cancelPeriodic(Timer? timer, String label) {
    timer?.cancel();
    final rid = _diagTimerResourceIds.remove(label);
    if (rid != null) {
      CfResourceTracker.cancelTimer(null, rid);
    }
  }

  void _attachRemoteMediaListeners() {
    if (!_remoteBind.tryAttach()) return;
    _remoteVideoListener ??= () {
      if (_disposed) return;
      final map = Map<String, bool>.from(_trtc.remoteVideoByUser.value);
      state = state.copyWith(remoteCamera: map);
      // Uzak video geldi → render takılması yedeği artık gereksiz.
      if (map.values.any((available) => available)) {
        _stopRemoteVideoWatchdog();
      }
      for (final entry in map.entries) {
        PsychicEventLog.remoteVideo(
          sessionId: session.sessionId,
          userId: entry.key,
          available: entry.value,
        );
      }
    };
    _remoteAudioListener ??= () {
      if (_disposed) return;
      final map = Map<String, bool>.from(_trtc.remoteAudioByUser.value);
      state = state.copyWith(remoteMicrophone: map);
      for (final entry in map.entries) {
        PsychicEventLog.remoteAudio(
          sessionId: session.sessionId,
          userId: entry.key,
          available: entry.value,
        );
      }
    };
    _remotePresenceListener ??= () {
      if (_disposed || state.leaving) return;
      // Karşı taraf (danışan) odaya girdi → falcı süre isteği gönderebilir.
      _maybeSendTimerStartRequest();
      if (!state.timerStarted) {
        unawaited(_pollRoomSignals());
        unawaited(_syncRoomInfo());
      }
    };
    _trtc.remoteVideoByUser.addListener(_remoteVideoListener!);
    _trtc.remoteAudioByUser.addListener(_remoteAudioListener!);
    _trtc.remoteAnchorUserIdNotifier.addListener(_remotePresenceListener!);
    _trtc.remoteUserIdsNotifier.addListener(_remotePresenceListener!);
  }

  void _detachRemoteMediaListeners() {
    if (!_remoteBind.tryDetach()) return;
    if (_remoteVideoListener != null) {
      _trtc.remoteVideoByUser.removeListener(_remoteVideoListener!);
    }
    if (_remoteAudioListener != null) {
      _trtc.remoteAudioByUser.removeListener(_remoteAudioListener!);
    }
    if (_remotePresenceListener != null) {
      _trtc.remoteAnchorUserIdNotifier.removeListener(_remotePresenceListener!);
      _trtc.remoteUserIdsNotifier.removeListener(_remotePresenceListener!);
    }
  }

  bool get _peerPresentInRoom {
    if (_trtc.remoteAnchorUserId?.trim().isNotEmpty ?? false) return true;
    return _trtc.remoteUserIdsNotifier.value.isNotEmpty;
  }

  /// Falcı: danışan odaya girmişken ve süre başlamamışken süre başlatma isteği
  /// gönderir (bir kez). Süre/ücret ancak danışan onaylayınca başlar.
  void _maybeSendTimerStartRequest({bool force = false}) {
    if (_disposed || state.leaving) return;
    var requestSent = state.timerStartRequestSent;
    if (requestSent &&
        !state.timerStarted &&
        _lastTimerStartRequestAt != null &&
        DateTime.now().difference(_lastTimerStartRequestAt!) >
            const Duration(seconds: 14)) {
      requestSent = false;
      state = state.copyWith(timerStartRequestSent: false);
    }
    if (!force &&
        !PsychicTimerHandshake.tellerShouldSendRequest(
          isClient: session.isClient,
          timerStarted: state.timerStarted,
          requestAlreadySent: requestSent,
          peerPresent: _peerPresentInRoom,
        )) {
      return;
    }
    if (force &&
        (session.isClient || state.timerStarted || state.leaving)) {
      return;
    }
    if (force && requestSent) {
      requestSent = false;
    }
    _lastTimerStartRequestAt = DateTime.now();
    state = state.copyWith(timerStartRequestSent: true);
    final peerId = session.remotePeerIdFor(room: state.room);
    unawaited(
      ref.read(livePsychicsRepositoryProvider).sendRoomSignal(
            sessionId: session.sessionId,
            type: PsychicTimerHandshake.signalRequest,
            data: const {'action': 'timer_start_request'},
            receiverId: peerId.isNotEmpty ? peerId : null,
          ),
    );
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'timer_start_request_sent',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
    );
  }

  void dismissTimerStartPrompt() {
    if (!_disposed && state.timerStartPrompt) {
      state = state.copyWith(timerStartPrompt: false);
    }
  }

  /// Süre başlamadan önce her iki tarafta A/V susturulur (gizlenir). Karşı
  /// tarafın sesi de duyulmaz; UI uzak videoyu gizler. Onaydan sonra açılır.
  void _gateMediaUntilTimerStart() {
    if (!PsychicTimerHandshake.shouldGateMedia(timerStarted: state.timerStarted)) {
      return;
    }
    _trtc.setMicEnabled(false);
    _trtc.setCameraEnabled(false);
    _trtc.setAllRemoteAudioMuted(true);
  }

  /// Danışan onayı: falcıya `timer_start_accept` sinyali yollar.
  Future<void> acceptTimerStart() async {
    if (_disposed || state.leaving || !session.isClient) return;
    state = state.copyWith(timerStartPrompt: false);
    final peerId = session.remotePeerIdFor(room: state.room);
    await ref.read(livePsychicsRepositoryProvider).sendRoomSignal(
          sessionId: session.sessionId,
          type: PsychicTimerHandshake.signalAccept,
          data: const {'action': 'timer_start_accept'},
          receiverId: peerId.isNotEmpty ? peerId : null,
        );
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'timer_start_accept_sent',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
    );
    for (var i = 0; i < 20 && !_disposed && !state.leaving; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await _syncRoomInfo();
      if (state.timerStarted) return;
    }
  }

  /// T+5s render takılması yedeği. Bağlantı kurulduktan sonra, karşı taraf
  /// odaya girmişken uzak video hâlâ gelmiyorsa, odaya dokunmadan (exitRoom /
  /// rejoin YOK) uzak view'i en fazla iki kez yeniden abone eder. Uzak video
  /// göründüğünde kendini durdurur.
  void _startRemoteVideoWatchdog() {
    _remoteVideoWatchdog?.cancel();
    _resubscribeAttempts = 0;
    _remoteVideoWatchdog =
        Timer.periodic(_remoteVideoWatchdogInterval, (_) => _checkRemoteVideoStall());
  }

  void _stopRemoteVideoWatchdog() {
    _remoteVideoWatchdog?.cancel();
    _remoteVideoWatchdog = null;
  }

  String? _currentRemotePeerId() {
    final anchor = _trtc.remoteAnchorUserId?.trim();
    if (anchor != null && anchor.isNotEmpty) return anchor;
    final ids = _trtc.remoteUserIdsNotifier.value;
    return ids.isNotEmpty ? ids.first : null;
  }

  void _checkRemoteVideoStall() {
    if (_disposed || state.leaving) {
      _stopRemoteVideoWatchdog();
      return;
    }
    final peer = _currentRemotePeerId();
    final remoteVideoSeen =
        peer != null && (_trtc.remoteVideoByUser.value[peer] ?? false);
    if (remoteVideoSeen || _resubscribeAttempts >= _maxResubscribeAttempts) {
      _stopRemoteVideoWatchdog();
      return;
    }
    if (peer == null) return;
    final shouldResub = _trtcConn.shouldResubscribeRemoteView(
      inRoom: _trtc.inRoom,
      peerPresent: true,
      remoteVideoSeen: remoteVideoSeen,
      attempts: _resubscribeAttempts,
      maxAttempts: _maxResubscribeAttempts,
    );
    if (!shouldResub) return;
    final applied = _trtc.resubscribeRemoteView(peer);
    if (!applied) return;
    _resubscribeAttempts++;
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'remote_video_resubscribe',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: peer,
      inRoom: _trtc.inRoom,
    );
    PsychicRtcSessionReport.record('remote_video_resubscribe', {
      'sessionId': session.sessionId,
      'peerId': peer,
      'attempt': _resubscribeAttempts,
    });
  }

  TrtcRoomManager get trtc => _trtc;
  bool get micOn => _trtc.micOn;
  bool get cameraOn => _trtc.cameraOn;

  String get channelId {
    final locked = _trtcConn.joinedTrtcRoomId?.trim();
    if (locked != null && locked.isNotEmpty) return locked;
    return session.sessionId.trim();
  }

  Future<void> _bootstrap() async {
    LiveDebugLog.log('psychic.session.bootstrap', {
      'sessionId': session.sessionId,
      'isClient': session.isClient,
    });
    PsychicRtcSessionReport.record('bootstrap', {
      'sessionId': session.sessionId,
      'isClient': session.isClient,
    });
    await PsychicSessionStore.save(session);
    _startTimers();
    if (!await _syncRoomInfo()) return;
    await _waitForRoomBootstrap();
    if (_disposed || state.leaving) return;
    // _waitForRoomBootstrap az önce senkronladıysa aynı veriyi tekrar çekme.
    final syncedAt = _lastRoomSyncAt;
    final fresh = syncedAt != null &&
        DateTime.now().difference(syncedAt) < const Duration(seconds: 2);
    if (!fresh && !await _syncRoomInfo()) return;
    // Sohbet yoklaması ve SSE, TRTC join'e bağlı değil: join (token + SDK)
    // yavaş/geç olsa da sohbet ve oda olayları beklemesin. SSE bağlanınca
    // yoklama kendini iptal eder.
    _startChatPoll();
    final sseConnect = _guarded<void>(null, _connectRoomSse);
    await _joinRtc();
    if (_disposed || state.leaving) return;
    await sseConnect;
  }

  /// Peer kimliği için oda bilgisi — TRTC join sessionId ile kilitlenir.
  Future<void> _waitForRoomBootstrap() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      if (!await _syncRoomInfo()) return;
      if (_disposed || state.leaving) return;
      final peer = session.remotePeerIdFor(room: state.room);
      if (peer.isNotEmpty) return;
      await Future<void>.delayed(Duration(milliseconds: 350 + attempt * 150));
    }
  }

  void _watchNetwork() {
    unawaited(_onlineSub?.cancel());
    _onlineSub = ref.read(connectivityServiceProvider).onlineStream.listen((online) {
      if (_disposed || state.leaving) return;
      PsychicEventLog.trtcState(
        sessionId: session.sessionId,
        connectionState: _trtcConn.phase.name,
        roomId: _trtcConn.tokenRequestRoomId,
        trtcRoomId: _trtcConn.joinedTrtcRoomId,
        userId: _trtcConn.joinedUserId,
        inRoom: _trtc.inRoom,
        online: online,
      );
      if (!online) return;
      unawaited(
        _reconnectTrtc(PsychicTrtcReconnectReason.networkRecovered),
      );
    });
  }

  void _wireTrtcCallbacks() {
    _trtc.onConnectionLost = () {
      if (_disposed || state.leaving) return;
      PsychicEventLog.trtcState(
        sessionId: session.sessionId,
        connectionState: 'connection_lost',
        roomId: _trtcConn.tokenRequestRoomId,
        trtcRoomId: _trtcConn.joinedTrtcRoomId,
        userId: _trtcConn.joinedUserId,
        inRoom: _trtc.inRoom,
        errorCode: 'connection_lost',
      );
      _setPhase(PsychicSessionPhase.reconnecting);
      state = state.copyWith(rtcReady: false);
      unawaited(
        _reconnectTrtc(PsychicTrtcReconnectReason.connectionLost),
      );
    };
  }

  void _logSkipRejoin(String incomingRoomId) {
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'skip_alias_rejoin',
      roomId: incomingRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
    );
  }

  void _scheduleSseAutoRetry() {
    if (_disposed || state.leaving || _sseAutoRetryCount >= _maxSseAutoRetry) {
      return;
    }
    _sseAutoRetryCount++;
    _sseAutoRetryTimer?.cancel();
    _sseAutoRetryTimer = Timer(const Duration(seconds: 2), () {
      if (_disposed || state.leaving) return;
      unawaited(retryRoomSse());
    });
  }

  /// Falcı manuel olarak süreyi başlatır (kılavuz §11.1) — acil yedek.
  Future<bool> startTimer() async {
    if (_disposed || state.leaving || state.timerStarted || session.isClient) {
      return false;
    }
    await _ensureTimerStarted();
    return state.timerStarted;
  }

  /// Falcı: danışana süre başlatma isteğini (yeniden) gönderir. Süre ancak
  /// danışan onayladığında başlar.
  void requestTimerStart() {
    if (_disposed || state.leaving || session.isClient || state.timerStarted) {
      return;
    }
    state = state.copyWith(timerStartRequestSent: false);
    _maybeSendTimerStartRequest(force: true);
  }

  Future<void> _ensureTimerStarted() async {
    if (_disposed || state.leaving || state.timerStarted) return;
    final result = await ref
        .read(livePsychicsRepositoryProvider)
        .roomAction(session.sessionId, 'start_timer');
    if (_disposed || result == null) return;
    await _syncRoomInfo();
  }

  void _startTimers() {
    _cancelPeriodic(_tick, 'session_tick');
    _tick = _periodic(const Duration(seconds: 1), (_) {
      if (_disposed || state.leaving) return;
      if (!state.timerStarted) return;
      final room = state.room;
      final local = state.remaining.inSeconds - 1;
      final secs = room != null && room.timerStarted
          ? room.remainingSeconds
          : local;
      if (room != null && room.timerStarted && state.remaining > Duration.zero) {
        CfAutoDetect.timerDrift(
          sessionId: session.sessionId,
          clientRemaining: local,
          serverRemaining: secs,
        );
      }
      if (secs <= 0) {
        unawaited(_onTimeUp());
        return;
      }
      var lowTimeWarning = state.lowTimeWarningPending;
      if (session.isClient &&
          !lowTimeWarning &&
          !state.timeUpPending &&
          secs <= 120) {
        lowTimeWarning = true;
      }
      state = state.copyWith(
        remaining: Duration(seconds: secs),
        lowTimeWarningPending: lowTimeWarning,
      );
    }, label: 'session_tick');

    _cancelPeriodic(_ping, 'session_ping');
    _ping = _periodic(const Duration(seconds: 60), (_) => _sendPing(),
        label: 'session_ping');

    _scheduleRoomPoll();
    _scheduleSignalPoll();
  }

  void _scheduleSignalPoll() {
    _cancelPeriodic(_signalPoll, 'signal_poll');
    if (_disposed) return;
    // Süre başlamadan önce süre-el-sıkışması sinyalleri (request/accept) hızlı
    // ulaşmalı → 2 sn. Süre başladıktan sonra sinyal poll yalnızca media_state
    // (RTC) için yedek olduğundan seyrekleşir (SSE bağlıysa).
    // FIX: Danışan poll interval 30s → 10s (hediye gecikme azaltma)
    final interval = !state.timerStarted
        ? const Duration(milliseconds: 900)
        : state.sseConnected
            ? (session.isClient
                ? const Duration(seconds: 10)
                : const Duration(seconds: 8))
            : const Duration(seconds: 2);
    _signalPoll = _periodic(interval, (_) {
      unawaited(_pollRoomSignals());
    }, label: 'signal_poll');
    if (CfDiagnosticLogger.active) {
      CfDiagnosticLogger.log(
        level: CfFileLogLevel.info,
        category: CfFileLogCategory.polling,
        message: 'POLLING_START',
        metadata: {
          'id': _diagTimerResourceIds['signal_poll'],
          'screen': 'LiveFortuneSession',
          'intervalMs': interval.inMilliseconds,
          'endpoint': 'room_signals',
        },
      );
    }
    unawaited(_pollRoomSignals());
  }

  void _scheduleRoomPoll() {
    _cancelPeriodic(_roomPoll, 'room_poll');
    if (_disposed) return;
    if (state.timerStarted && state.sseConnected) return;
    final interval = !state.timerStarted
        ? const Duration(seconds: 2)
        : state.sseConnected
            ? const Duration(seconds: 20)
            : const Duration(seconds: 3);
    _roomPoll = _periodic(interval, (_) {
      unawaited(_syncRoomInfo());
    }, label: 'room_poll');
    if (CfDiagnosticLogger.active) {
      CfDiagnosticLogger.log(
        level: CfFileLogLevel.info,
        category: CfFileLogCategory.polling,
        message: 'POLLING_START',
        metadata: {
          'id': _diagTimerResourceIds['room_poll'],
          'screen': 'LiveFortuneSession',
          'intervalMs': interval.inMilliseconds,
          'endpoint': 'room_info',
        },
      );
    }
    if (!state.timerStarted) {
      unawaited(_syncRoomInfo());
    }
  }

  /// Zamanlayıcıdan `unawaited` çağrılan yoklamalardaki hata yakalanmamış
  /// async hataya dönüşmesin; kaydedilir ve güvenli değer döner.
  Future<T> _guarded<T>(T fallback, Future<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      CfDiag.recordError(e, st, category: CfCategory.fortune);
      return fallback;
    }
  }

  Future<void> _pollRoomSignals() =>
      _signalsFlight.run(() => _guarded<void>(null, _pollRoomSignalsOnce));

  Future<void> _pollRoomSignalsOnce() async {
    if (_disposed || state.leaving) return;
    _signalsHttpCancel?.cancel('superseded');
    final token = CancelToken();
    _signalsHttpCancel = token;
    final repo = ref.read(livePsychicsRepositoryProvider);
    List<Map<String, dynamic>> signals;
    try {
      signals = await repo.fetchRoomSignals(
        session.sessionId,
        cancelToken: token,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      rethrow;
    }
    if (_disposed || state.leaving || token.isCancelled) return;
    for (final sig in signals) {
      // Signal ID: backend tarafından sağlanan 'id' veya timestamp + type + index oluştur.
      final id = sig['id']?.toString() ??
          sig['signalId']?.toString() ??
          sig['eventId']?.toString() ??
          '${sig['type']}_${sig['createdAt'] ?? sig['timestamp'] ?? ''}';
      if (id.isEmpty || !_seenSignalIds.add(id)) continue;
      final type = (sig['type'] ?? '').toString().toLowerCase();
      if (type.contains('session_end') || type.contains('end_session')) {
        unawaited(_handleRemoteSessionEnded(PsychicSessionStatus.ended));
        return;
      }
      if (type.contains('media_state') || type.contains('rtc_state')) {
        _onPeerMediaSignal(sig);
        continue;
      }
      if (PsychicTimerHandshake.signalMatches(
        sig,
        PsychicTimerHandshake.signalRequest,
      )) {
        _onTimerStartRequestSignal();
        continue;
      }
      if (PsychicTimerHandshake.signalMatches(
        sig,
        PsychicTimerHandshake.signalAccept,
      )) {
        unawaited(_onTimerStartAcceptSignal());
        continue;
      }
      if (!session.isClient &&
          (type.contains('tip') ||
              type.contains('bahsis') ||
              type.contains('gift') ||
              type.contains('hediye'))) {
        final data = _mergeSignalPayload(sig);
        final amountRaw = data['amount'] ??
            data['jeton'] ??
            data['tipAmount'] ??
            data['giftValue'] ??
            data['coins'] ??
            data['coin'] ??
            data['price'] ??
            data['value'] ??
            sig['amount'];
        final amount = amountRaw is num
            ? amountRaw.round()
            : int.tryParse('$amountRaw') ?? 0;
        final from = data['fromName']?.toString() ??
            data['senderName']?.toString() ??
            data['from']?.toString();
        _onTipReceived(amount, from, eventId: id);
      }
    }
  }

  Map<String, dynamic> _mergeSignalPayload(Map<String, dynamic> sig) {
    final merged = Map<String, dynamic>.from(sig);
    for (final key in ['data', 'payload', 'body']) {
      final nested = sig[key];
      if (nested is Map) {
        merged.addAll(Map<String, dynamic>.from(nested));
      }
    }
    return merged;
  }

  void _onPeerMediaSignal(Map<String, dynamic> sig) {
    // Karşı tarafın medya durumu — yalnızca log; TRTC akışı zorlanmaz.
    final data = sig['data'] is Map
        ? Map<String, dynamic>.from(sig['data'] as Map)
        : sig;
    LiveDebugLog.log('psychic.media.peer', {
      'sessionId': session.sessionId,
      'cameraEnabled': data['cameraEnabled'] ?? data['cameraOn'],
      'micEnabled': data['micEnabled'] ?? data['micOn'],
    });
  }

  /// Danışan: falcının süre başlatma isteği geldi → onay istemi göster.
  void _onTimerStartRequestSignal() {
    if (_disposed || state.leaving) return;
    if (!PsychicTimerHandshake.clientShouldPrompt(
      isClient: session.isClient,
      timerStarted: state.timerStarted,
      promptAlreadyShown: state.timerStartPrompt,
    )) {
      return;
    }
    state = state.copyWith(timerStartPrompt: true);
  }

  /// Falcı: danışan onayladı → süreyi (ve ücreti) başlat.
  Future<void> _onTimerStartAcceptSignal() async {
    if (_disposed || state.leaving) return;
    if (!PsychicTimerHandshake.tellerShouldStartTimer(
      isClient: session.isClient,
      timerStarted: state.timerStarted,
    )) {
      return;
    }
    for (var attempt = 0; attempt < 4; attempt++) {
      await _ensureTimerStarted();
      if (_disposed || state.timerStarted) return;
      await _syncRoomInfo();
      if (state.timerStarted) return;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }

  Future<void> _broadcastMediaState() async {
    if (_disposed || state.leaving) return;
    final peerId = session.remotePeerIdFor(room: state.room);
    if (peerId.isEmpty) return;
    unawaited(
      ref.read(livePsychicsRepositoryProvider).sendRoomSignal(
            sessionId: session.sessionId,
            type: 'media_state',
            data: {
              'cameraEnabled': _trtc.cameraOn,
              'micEnabled': _trtc.micOn,
              'videoPublished': _trtc.cameraOn,
              'audioPublished': _trtc.micOn,
            },
            receiverId: peerId,
          ),
    );
  }

  /// `false` → seans sunucuda bitmiş / ayrılıyor; TRTC/SSE başlatma.
  Future<bool> _syncRoomInfo() => _roomSync.run(() async {
        // Hata → «devam et» (true): API geçici hatasında bağlantı akışı
        // sessizce yarım kalmasın.
        final ok = await _guarded<bool>(true, _syncRoomInfoOnce);
        _lastRoomSyncAt = DateTime.now();
        return ok;
      });

  Future<bool> _syncRoomInfoOnce() async {
    if (_disposed || state.leaving) return false;
    _roomSyncHttpCancel?.cancel('superseded');
    final token = CancelToken();
    _roomSyncHttpCancel = token;
    final repo = ref.read(livePsychicsRepositoryProvider);
    // Oda ve durum sorguları birbirinden bağımsız: sırayla değil birlikte.
    // İkisi de BİTMEDEN dönülmez: biri hata verirse diğeri havada kalıp bir
    // sonraki senkronla üst üste binmesin.
    Object? roomError;
    StackTrace? roomStack;
    final roomFuture = repo
        .fetchRoom(session.sessionId, cancelToken: token)
        .then<PsychicRoomEntity?>(
      (v) => v,
      onError: (Object e, StackTrace st) {
        if (e is DioException && CancelToken.isCancel(e)) return null;
        roomError = e;
        roomStack = st;
        return null;
      },
    );
    final statusFuture = repo
        .fetchSessionStatus(session.sessionId, cancelToken: token)
        .then<PsychicSessionStatusResult?>((v) => v, onError: (Object e, _) {
      if (e is DioException && CancelToken.isCancel(e)) return null;
      return null;
    });
    final info = await roomFuture;
    final statusResult = await statusFuture;
    if (roomError != null) {
      Error.throwWithStackTrace(roomError!, roomStack ?? StackTrace.current);
    }
    if (_disposed || state.leaving || token.isCancelled) return false;
    if (info == null) return true;

    if (info.status == PsychicSessionStatus.cancelled ||
        info.status == PsychicSessionStatus.rejected ||
        info.status == PsychicSessionStatus.ended ||
        info.status == PsychicSessionStatus.expired) {
      await _handleRemoteSessionEnded(info.status);
      return false;
    }

    if (statusResult != null &&
        (statusResult.status == PsychicSessionStatus.cancelled ||
            statusResult.status == PsychicSessionStatus.rejected ||
            statusResult.status == PsychicSessionStatus.ended ||
            statusResult.status == PsychicSessionStatus.expired)) {
      await _handleRemoteSessionEnded(statusResult.status);
      return false;
    }

    final wasTimerStarted = state.timerStarted;
    final maxMinutes =
        info.maxMinutes > 0 ? info.maxMinutes : session.durationMinutes;

    var room = info.copyWith(maxMinutes: maxMinutes);
    var timerStarted = info.timerStarted;
    var waitingForTimer = session.isClient && !info.timerStarted;
    var remaining = state.remaining;
    if (info.timerStarted) {
      remaining = Duration(seconds: info.remainingSeconds);
    } else if (!wasTimerStarted) {
      remaining = Duration(minutes: maxMinutes);
    }

    state = state.copyWith(
      room: room,
      timerStarted: timerStarted,
      waitingForTimer: waitingForTimer,
      remaining: remaining,
    );

    // SSE yoksa da süre başlangıcını yakala → A/V aç, handshake temizle.
    if (timerStarted && !wasTimerStarted) {
      unawaited(_onTimerStartedFromServer());
    }

    if (room.tellerUserId != null ||
        room.clientId != null ||
        (room.roomId?.trim().isNotEmpty ?? false)) {
      session = session.copyWith(
        tellerUserId: room.tellerUserId ?? session.tellerUserId,
        clientId: room.clientId ?? session.clientId,
        trtcRoomIdOverride: room.roomId?.trim().isNotEmpty == true
            ? room.roomId
            : session.trtcRoomIdOverride,
      );
      unawaited(PsychicSessionStore.save(session));
    }

    final incomingRoomId = room.roomId;
    if (incomingRoomId != null &&
        incomingRoomId.isNotEmpty &&
        _trtcConn.joinedTrtcRoomId != null) {
      if (PsychicTrtcIdentity.isAliasDrift(
            sessionId: session.sessionId,
            joinedTrtcRoom: _trtcConn.joinedTrtcRoomId,
            incomingRoomId: incomingRoomId,
          ) ||
          PsychicTrtcIdentity.sameChannel(
            incomingRoomId,
            session.sessionId,
            sessionId: session.sessionId,
          )) {
        _logSkipRejoin(incomingRoomId);
      }
    }
    return true;
  }

  Future<void> _sendPing() =>
      _pingFlight.run(() => _guarded<void>(null, _sendPingOnce));

  Future<void> _sendPingOnce() async {
    if (_disposed || state.leaving || !state.timerStarted) return;
    final result = await ref
        .read(livePsychicsRepositoryProvider)
        .roomAction(session.sessionId, 'ping');
    if (_disposed || result == null) return;
    if (result['timerStarted'] == true) {
      await _syncRoomInfo();
    }
  }

  void _startChatPoll() {
    _cancelPeriodic(_chatPoll, 'chat_poll');
    if (_disposed || state.sseConnected) return;
    const interval = Duration(seconds: 3);
    _chatPoll = _periodic(interval, (_) => unawaited(_pollChat()),
        label: 'chat_poll');
    unawaited(_pollChat());
  }

  Future<void> _connectRoomSse() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    final storage = ref.read(tokenStorageProvider);
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    await ref.read(psychicRoomSseServiceProvider).connect(
          sessionId: session.sessionId,
          accessToken: storage.readAccess,
          refreshTokens: () => tryRefreshAccessToken(refreshDio, storage),
          myUserId: user?.id,
          onConnected: () {
            if (_disposed) return;
            _sseAutoRetryCount = 0;
            _sseAutoRetryTimer?.cancel();
            if (!state.sseConnected || state.sseFailed) {
              state = state.copyWith(sseConnected: true, sseFailed: false);
              _cancelPeriodic(_chatPoll, 'chat_poll');
              _cancelPeriodic(_roomPoll, 'room_poll');
              _scheduleSignalPoll();
            }
          },
          onFailed: () {
            if (_disposed || state.leaving) return;
            state = state.copyWith(sseConnected: false, sseFailed: true);
            _scheduleRoomPoll();
            _startChatPoll();
            _scheduleSignalPoll();
            _scheduleSseAutoRetry();
          },
          onMessage: _onSseChatMessage,
          onRoomUpdate: _onSseRoomUpdate,
          onSessionEnded: (status) {
            if (_disposed || state.leaving) return;
            unawaited(_handleRemoteSessionEnded(status));
          },
          onTipReceived: (amount, fromName, eventId) {
            if (_disposed || state.leaving) return;
            _onTipReceived(
              amount,
              fromName,
              eventId: eventId,
            );
          },
          onSignal: (type, data) {
            if (_disposed || state.leaving) return;
            _handleSseSignal(type, data);
          },
        );
  }

  void _handleSseSignal(String type, Map<String, dynamic>? data) {
    final sig = <String, dynamic>{'type': type};
    if (data != null && data.isNotEmpty) {
      sig['data'] = data;
    }

    if (PsychicTimerHandshake.signalMatches(
      sig,
      PsychicTimerHandshake.signalAccept,
    )) {
      if (!session.isClient) {
        state = state.copyWith(timerStartPrompt: false);
        unawaited(_onTimerStartAcceptSignal());
      }
      return;
    }

    if (PsychicTimerHandshake.signalMatches(
      sig,
      PsychicTimerHandshake.signalRequest,
    )) {
      if (session.isClient) {
        _onTimerStartRequestSignal();
      }
      return;
    }
  }

  void _onTipReceived(int amount, String? fromName, {String? eventId}) {
    if (amount <= 0) return;
    final id = eventId?.trim();
    if (id != null && id.isNotEmpty) {
      if (!_seenTipEventIds.add(id)) return;
    } else {
      // Fallback eventId: timestamp + miktar + göndericiye bağlı tekil ID.
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      final fromNameNorm = (fromName ?? '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final fallbackId = 'tip-$nowMs-$amount-$fromNameNorm';
      if (!_seenTipEventIds.add(fallbackId)) return;
      final last = _lastTipReceivedPopupAt;
      if (last != null &&
          now.difference(last) < const Duration(seconds: 2)) {
        _scheduleTipReceivedDismiss();
        return;
      }
      _lastTipReceivedPopupAt = now;
    }

    // Danışan yalnızca kendi gönderim teşekkürünü görür; falcı SSE/sinyal popup alır.
    if (session.isClient) return;

    final total = state.sessionTipsTotal + amount;
    state = state.copyWith(
      tipReceivedAmount: amount,
      tipReceivedFrom: fromName,
      sessionTipsTotal: total,
    );
    _scheduleTipReceivedDismiss();
  }

  void dismissTipThankYouOverlay() {
    _tipThankYouDismissTimer?.cancel();
    _tipThankYouDismissTimer = null;
    if (!_disposed && state.tipThankYouAmount != null) {
      state = state.copyWith(clearTipThankYou: true);
    }
  }

  void dismissTipReceivedOverlay() {
    _tipReceivedDismissTimer?.cancel();
    _tipReceivedDismissTimer = null;
    if (!_disposed && state.tipReceivedAmount != null) {
      state = state.copyWith(clearTipReceived: true);
    }
  }

  void _scheduleTipThankYouDismiss() {
    _tipThankYouDismissTimer?.cancel();
    _tipThankYouDismissTimer = Timer(_tipOverlayDismissDuration, () {
      _tipThankYouDismissTimer = null;
      dismissTipThankYouOverlay();
    });
  }

  void _scheduleTipReceivedDismiss() {
    _tipReceivedDismissTimer?.cancel();
    _tipReceivedDismissTimer = Timer(_tipOverlayDismissDuration, () {
      _tipReceivedDismissTimer = null;
      dismissTipReceivedOverlay();
    });
  }

  void _onSseChatMessage(PsychicChatMessage msg) {
    if (_disposed || state.leaving) return;
    if (_seenChatIds.contains(msg.id)) return;
    _seenChatIds.add(msg.id);
    final created = msg.createdAt?.toUtc().toIso8601String();
    if (created != null && created.isNotEmpty) {
      _lastChatAfter = created;
    }
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void _onSseRoomUpdate(PsychicRoomEntity info) {
    if (_disposed || state.leaving) return;
    if (info.status == PsychicSessionStatus.cancelled ||
        info.status == PsychicSessionStatus.rejected ||
        info.status == PsychicSessionStatus.ended ||
        info.status == PsychicSessionStatus.expired) {
      unawaited(_handleRemoteSessionEnded(info.status));
      return;
    }
    final wasTimerStarted = state.timerStarted;
    var remaining = state.remaining;
    if (info.timerStarted) {
      remaining = Duration(seconds: info.remainingSeconds);
    } else if (info.maxMinutes > (state.room?.maxMinutes ?? 0)) {
      final added = info.maxMinutes - (state.room?.maxMinutes ?? session.durationMinutes);
      if (added > 0) {
        remaining = state.remaining + Duration(minutes: added);
      }
    }
    state = state.copyWith(
      room: info,
      timerStarted: info.timerStarted,
      waitingForTimer: session.isClient && !info.timerStarted,
      remaining: remaining,
      lowTimeWarningPending: remaining.inSeconds > 120
          ? false
          : state.lowTimeWarningPending,
    );
    if (info.timerStarted && !wasTimerStarted) {
      unawaited(_onTimerStartedFromServer());
    }
    if (info.roomId != null &&
        info.roomId!.isNotEmpty &&
        _trtcConn.joinedTrtcRoomId != null) {
      _logSkipRejoin(info.roomId!);
    }
  }

  Future<void> _onTimerStartedFromServer() async {
    if (_disposed || state.leaving) return;
    // Onay sonrası: A/V açılır, karşı tarafın sesi duyulur, handshake temizlenir.
    _trtc.setAllRemoteAudioMuted(false);
    if (!_trtc.micOn) {
      _trtc.setMicEnabled(true);
    }
    if (session.preferVideo) {
      if (!_trtc.cameraOn) {
        _trtc.setCameraEnabled(true);
      }
    } else if (_trtc.cameraOn) {
      _trtc.setCameraEnabled(false);
    }
    if (state.timerStartPrompt || state.timerStartRequestSent) {
      state = state.copyWith(
        timerStartPrompt: false,
        timerStartRequestSent: false,
      );
    }
    _scheduleSignalPoll();
    unawaited(_broadcastMediaState());
  }

  Future<void> _pollChat() =>
      _chatFlight.run(() => _guarded<void>(null, _pollChatOnce));

  Future<void> _pollChatOnce() async {
    if (_disposed || state.leaving) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    final incoming = await ref.read(livePsychicsRepositoryProvider).fetchMessages(
          session.sessionId,
          myUserId: user?.id,
          afterIso: _lastChatAfter,
        );
    if (_disposed || incoming.isEmpty) return;
    final merged = [...state.messages];
    var changed = false;
    for (final msg in incoming) {
      if (_seenChatIds.contains(msg.id)) continue;
      _seenChatIds.add(msg.id);
      merged.add(msg);
      final created = msg.createdAt?.toUtc().toIso8601String();
      if (created != null && created.isNotEmpty) {
        _lastChatAfter = created;
      }
      changed = true;
    }
    if (changed) {
      state = state.copyWith(messages: merged);
    }
  }

  Future<void> _joinRtc() async {
    final user = await _waitForAuth();
    if (user == null) {
      state = state.copyWith(rtcError: 'Oturum için giriş gerekli');
      return;
    }
    if (!_trtc.isSupported) {
      state = state.copyWith(rtcError: 'Video bu cihazda desteklenmiyor');
      return;
    }
    await _joinTrtc(user: user);
  }

  String _tokenRequestRoomId() {
    final locked = _trtcConn.tokenRequestRoomId?.trim();
    if (locked != null && locked.isNotEmpty) return locked;
    return session.trtcRoomId.trim();
  }

  Future<void> _joinTrtc({required UserEntity user}) async {
    if (!_trtcConn.tryBeginJoin()) return;
    _setPhase(PsychicSessionPhase.joining);
    final requestRoomId = _tokenRequestRoomId();
    if (_trtc.inRoom) {
      final joined = _trtc.joinedStrRoomId;
      if (joined != null &&
          joined.isNotEmpty &&
          !PsychicTrtcIdentity.sameChannel(
            joined,
            requestRoomId,
            sessionId: session.sessionId,
          )) {
        await _trtc.leave();
      }
    }
    if (requestRoomId.isEmpty) {
      _trtcConn.markJoinFailed();
      state = state.copyWith(rtcError: 'Oda bilgisi alınamadı. Tekrar deneyin.');
      return;
    }
    try {
      PsychicEventLog.joinStart(
        sessionId: session.sessionId,
        roomId: requestRoomId,
      );
      LiveDebugLog.log('psychic.trtc.join.request', {
        'sessionId': session.sessionId,
        'roomId': requestRoomId,
        'userId': user.id,
      });

      if (_trtc.inRoom &&
          _trtcConn.alreadyJoined(
            sessionId: session.sessionId,
            trtcRoomId: _trtc.joinedStrRoomId,
            inRoom: true,
          )) {
        _wireTrtcCallbacks();
        _attachRemoteMediaListeners();
        _trtcConn.markConnected(
          sessionId: session.sessionId,
          tokenRequestRoomId: requestRoomId,
          joinedTrtcRoomId: _trtc.joinedStrRoomId ?? requestRoomId,
          joinedUserId: user.id,
          remoteUserId: session.remotePeerIdFor(room: state.room),
        );
        state = state.copyWith(
          rtcReady: true,
          rtcBackend: PsychicRtcBackend.trtc,
          clearRtcError: true,
        );
        _setPhase(PsychicSessionPhase.connected);
        _startRemoteVideoWatchdog();
        _gateMediaUntilTimerStart();
        _maybeSendTimerStartRequest();
        return;
      }

      if (_trtc.inRoom) {
        final existing = _trtc.joinedStrRoomId;
        if (existing != null &&
            existing.isNotEmpty &&
            !PsychicTrtcIdentity.sameChannel(
              existing,
              requestRoomId,
              sessionId: session.sessionId,
            )) {
          await _trtc.leave();
        }
      }

      final tokenWatch = Stopwatch()..start();
      // Token isteği sonsuza dek beklemesin (join bu yüzden hiç başlamıyordu).
      final creds = await ref
          .read(trtcRemoteProvider)
          .fetchToken(
            roomId: requestRoomId,
            role: session.isClient ? 'audience' : 'host',
            userId: user.id,
          )
          .timeout(const Duration(seconds: 20));
      CfDiag.record(
        CfCategory.trtc,
        'TRTC token ${tokenWatch.elapsedMilliseconds}ms',
        data: {'sessionId': session.sessionId},
      );
      if (!creds.isValid) {
        throw StateError('TRTC token geçersiz');
      }
      TrtcSessionStore.put(creds);

      PsychicEventLog.trtcState(
        sessionId: session.sessionId,
        connectionState: 'token_ok',
        roomId: requestRoomId,
        trtcRoomId: creds.effectiveStrRoomId,
        userId: creds.userId,
      );

      final joinWatch = Stopwatch()..start();
      await _trtc.join(
        credentials: creds,
        isHost: !session.isClient,
        twoWayVideo: true,
        expectedAnchorUserId: session.remotePeerIdFor(room: state.room),
      );
      CfDiag.record(
        CfCategory.trtc,
        'TRTC join ${joinWatch.elapsedMilliseconds}ms',
        data: {'sessionId': session.sessionId},
      );
      _wireTrtcCallbacks();
      PsychicEventLog.trtcJoin(
        sessionId: session.sessionId,
        role: session.isClient ? 'client' : 'host',
      );

      _trtcConn.markConnected(
        sessionId: session.sessionId,
        tokenRequestRoomId: requestRoomId,
        joinedTrtcRoomId: creds.effectiveStrRoomId,
        joinedUserId: creds.userId,
        remoteUserId: session.remotePeerIdFor(room: state.room),
      );
      ref.read(liveBeautyProvider.notifier).bindRtc(trtc: _trtc);
      _attachRemoteMediaListeners();
      PsychicEventLog.joinSuccess(
        sessionId: session.sessionId,
        roomId: creds.effectiveStrRoomId,
      );
      PsychicEventLog.trtcState(
        sessionId: session.sessionId,
        connectionState: _trtcConn.phase.name,
        roomId: requestRoomId,
        trtcRoomId: creds.effectiveStrRoomId,
        userId: creds.userId,
        inRoom: _trtc.inRoom,
        joinResult: 1,
      );
      PsychicEventLog.localAudio(enabled: _trtc.micOn, sessionId: session.sessionId);
      PsychicEventLog.localVideo(enabled: _trtc.cameraOn, sessionId: session.sessionId);
      LiveDebugLog.log('psychic.trtc.join.ok', {
        'sessionId': session.sessionId,
        'roomId': requestRoomId,
        'trtcRoomId': creds.effectiveStrRoomId,
      });
      PsychicRtcSessionReport.record('join_ok', {
        'sessionId': session.sessionId,
        'roomId': requestRoomId,
        'trtcRoomId': creds.effectiveStrRoomId,
        'micOn': _trtc.micOn,
        'cameraOn': _trtc.cameraOn,
        'isClient': session.isClient,
      });
      state = state.copyWith(
        rtcReady: true,
        rtcBackend: PsychicRtcBackend.trtc,
        clearRtcError: true,
      );
      _setPhase(PsychicSessionPhase.connected);
      _startRemoteVideoWatchdog();
      // Süre el sıkışması: süre/ücret başlamadan önce A/V susturulur; falcı
      // danışan geldiğinde başlatma isteği gönderir (otomatik başlatma YOK).
      _gateMediaUntilTimerStart();
      unawaited(_broadcastMediaState());
      _maybeSendTimerStartRequest();
    } catch (e, st) {
      CfDiag.recordError(e, st, category: CfCategory.trtc);
      PsychicEventLog.error('join', e, sessionId: session.sessionId);
      PsychicEventLog.trtcState(
        sessionId: session.sessionId,
        connectionState: 'error',
        roomId: requestRoomId,
        trtcRoomId: _trtcConn.joinedTrtcRoomId,
        userId: user.id,
        errorMessage: ApiException.userMessage(e),
        inRoom: _trtc.inRoom,
      );
      _trtcConn.markJoinFailed();
      _setPhase(PsychicSessionPhase.error);
      state = state.copyWith(rtcError: ApiException.userMessage(e));
    }
  }

  Future<void> _reconnectTrtc(PsychicTrtcReconnectReason reason) async {
    if (_disposed || state.leaving) return;
    if (!_trtcConn.tryBeginReconnect(reason, inRoom: _trtc.inRoom)) {
      return;
    }
    _setPhase(PsychicSessionPhase.reconnecting);
    state = state.copyWith(rtcReady: false, clearRtcError: true);
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'reconnecting',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
      errorCode: reason.name,
    );
    try {
      await _trtc.leave();
      final user = await _waitForAuth();
      if (user == null) {
        _trtcConn.markReconnectFinished();
        state = state.copyWith(rtcError: 'Oturum için giriş gerekli');
        return;
      }
      _trtcConn.markReconnectFinished();
      await _joinTrtc(user: user);
    } catch (e) {
      _trtcConn.markReconnectFinished();
      _trtcConn.markJoinFailed();
      _setPhase(PsychicSessionPhase.error);
      state = state.copyWith(rtcError: ApiException.userMessage(e));
    }
  }

  Future<void> retryRtc() async {
    if (_disposed || state.leaving) return;
    if (_trtc.inRoom && state.rtcReady) return;
    if (_trtc.inRoom) {
      await _reconnectTrtc(PsychicTrtcReconnectReason.connectionLost);
      return;
    }
    await _joinRtc();
  }

  Future<void> _handleRemoteSessionEnded(PsychicSessionStatus status) async {
    if (_disposed || state.leaving || _remoteEndHandled) return;
    _remoteEndHandled = true;
    final msg = session.isClient
        ? 'Falcı görüşmeyi sonlandırdı.'
        : 'Kullanıcı görüşmeyi sonlandırdı.';
    if (ref.read(psychicSessionEndedProvider) == null) {
      ref.read(psychicSessionEndedProvider.notifier).state =
          PsychicSessionEndedEvent(
        sessionId: session.sessionId,
        tellerId: session.psychic.id,
        tellerName: session.psychic.name,
        durationMinutes: session.durationMinutes,
        totalJeton: session.totalJeton,
        tipsJeton: !session.isClient && state.sessionTipsTotal > 0
            ? state.sessionTipsTotal
            : null,
        isTeller: !session.isClient,
        promptReview: session.isClient,
        navigateAfter: true,
        message: msg,
      );
    }
    ref.read(psychicPeerLeftProvider.notifier).notifyPeerLeft(
          sessionId: session.sessionId,
          message: msg,
        );
    await leave(silent: true, peerEndedMessage: msg);
  }

  Future<void> sendChat(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.sendingChat) return;
    state = state.copyWith(sendingChat: true, clearRtcError: true);
    try {
      final ok = await ref
          .read(livePsychicsRepositoryProvider)
          .sendMessage(session.sessionId, t);
      if (!ok && !_disposed) {
        state = state.copyWith(
          sendingChat: false,
          rtcError: 'Mesaj gönderilemedi. Bağlantınızı kontrol edin.',
        );
        return;
      }
      unawaited(_pollChat());
    } finally {
      if (!_disposed) state = state.copyWith(sendingChat: false);
    }
  }

  Future<int?> openTipSheet(BuildContext context) async {
    final balance = ref.read(coinBalanceProvider) ??
        ref.read(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    return showPsychicTipSheet(
      context,
      psychicName: session.psychic.name,
      jetonBalance: balance,
    );
  }

  Future<bool> sendTip(int amount) async {
    final ok = await ref.read(livePsychicsRepositoryProvider).sendTip(
          sessionId: session.sessionId,
          amount: amount,
          tellerId: session.psychic.id,
          tellerUserId: session.tellerUserId,
        );
    if (ok) {
      invalidateWalletCacheFromRef(ref);
      state = state.copyWith(tipThankYouAmount: amount);
      _scheduleTipThankYouDismiss();
      final tellerUid = session.tellerUserId ??
          state.room?.tellerUserId ??
          session.psychic.userId;
      unawaited(
        ref.read(livePsychicsRepositoryProvider).sendRoomSignal(
              sessionId: session.sessionId,
              type: 'tip',
              data: {
                'amount': amount,
                'senderName':
                    ref.read(authControllerProvider).valueOrNull?.display,
                'senderId': ref.read(authControllerProvider).valueOrNull?.id,
              },
              receiverId: tellerUid,
            ),
      );
    }
    return ok;
  }

  Future<PsychicExtendOption?> openExtendSheet(BuildContext context) async {
    final perMin = session.psychic.pricePerMinute > 0
        ? session.psychic.pricePerMinute
        : 10;
    final isStaff =
        ref.read(walletBalancesProvider).valueOrNull?.isStaff == true;
    final balance = ref.read(coinBalanceProvider) ??
        ref.read(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    return showPsychicExtendSheet(
      context,
      jetonBalance: isStaff ? 999999999 : balance,
      jetonPerMinute: perMin,
      staffExempt: isStaff,
    );
  }

  Future<bool> tellerAddTime(PsychicExtendOption choice) async {
    final ok = await ref.read(livePsychicsRepositoryProvider).tellerAddTime(
          sessionId: session.sessionId,
          minutes: choice.minutes,
        );
    if (ok) {
      invalidateWalletCacheFromRef(ref);
      await _syncRoomInfo();
      final room = state.room;
      state = state.copyWith(
        remaining: state.remaining + Duration(minutes: choice.minutes),
        room: room?.copyWith(maxMinutes: (room.maxMinutes) + choice.minutes),
      );
    }
    return ok;
  }

  Future<bool> extendSession(PsychicExtendOption choice) async {
    final ok = await ref.read(livePsychicsRepositoryProvider).extendSession(
          sessionId: session.sessionId,
          minutes: choice.minutes,
        );
    if (ok) {
      invalidateWalletCacheFromRef(ref);
      await _syncRoomInfo();
      final room = state.room;
      state = state.copyWith(
        remaining: state.remaining + Duration(minutes: choice.minutes),
        room: room?.copyWith(maxMinutes: room.maxMinutes + choice.minutes),
      );
    }
    return ok;
  }

  Future<void> _onTimeUp() async {
    _tick?.cancel();
    _signalPoll?.cancel();
    if (_disposed || state.leaving) return;
    if (session.isClient) {
      state = state.copyWith(timeUpPending: true);
      return;
    }
    await leave(silent: true);
  }

  Future<void> handleClientTimeUp(BuildContext context) async {
    if (_disposed || state.leaving || !state.timeUpPending) return;
    state = state.copyWith(timeUpPending: false);
    final choice = await openExtendSheet(context);
    if (_disposed || state.leaving) return;
    if (choice != null) {
      final ok = await extendSession(choice);
      if (ok && !_disposed && !state.leaving) {
        _startTimers();
        return;
      }
    }
    if (state.remaining.inSeconds > 0) {
      _startTimers();
      return;
    }
    await leave(silent: true);
  }

  void toggleMic() {
    final next = !_trtc.micOn;
    _trtc.setMicEnabled(next);
    PsychicEventLog.localAudio(enabled: next, sessionId: session.sessionId);
    unawaited(_broadcastMediaState());
  }

  void toggleCamera() {
    final next = !_trtc.cameraOn;
    _trtc.setCameraEnabled(next);
    PsychicEventLog.localVideo(enabled: next, sessionId: session.sessionId);
    unawaited(_broadcastMediaState());
  }

  void switchCamera() {
    if (!_trtc.cameraOn) {
      _trtc.setCameraEnabled(true);
      PsychicEventLog.localVideo(enabled: true, sessionId: session.sessionId);
    }
    _trtc.switchCamera();
    state = state.copyWith(localPreviewKey: state.localPreviewKey + 1);
  }

  Future<void> retryRoomSse() async {
    if (_disposed || state.leaving) return;
    state = state.copyWith(sseFailed: false);
    await ref.read(psychicRoomSseServiceProvider).retryConnection();
  }

  Future<void> leave({
    bool silent = false,
    String? peerEndedMessage,
  }) async {
    if (state.leaving) return;
    _setPhase(PsychicSessionPhase.ending);
    state = state.copyWith(leaving: true);
    _stopRemoteVideoWatchdog();
    _detachRemoteMediaListeners();
    _trtc.setMicEnabled(false);
    _trtc.setCameraEnabled(false);
    _tick?.cancel();
    _chatPoll?.cancel();
    _ping?.cancel();
    _roomPoll?.cancel();
    _signalPoll?.cancel();
    ref.read(psychicSessionCancelSignalProvider.notifier).signal(session.sessionId);
    final user = ref.read(authControllerProvider).valueOrNull;
    final tipsTotal = state.sessionTipsTotal;
    final sessionId = session.sessionId;
    final isClient = session.isClient;
    final tellerReceiver = state.room?.tellerUserId ?? session.tellerUserId;
    final clientReceiver = state.room?.clientId;
    // ref'i navigasyon/dispose öncesi oku — autoDispose sonrası ref.read atmasın.
    final repo = ref.read(livePsychicsRepositoryProvider);
    final sse = ref.read(psychicRoomSseServiceProvider);

    // 1) RTC'yi kapat — exitRoom bitmeden yeni enterRoom yok (gate).
    _trtcConn.tryBeginLeave();
    try {
      await _trtc.leave().timeout(const Duration(seconds: 2));
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.fortune, 'psychic_video_controller:1769');
    }
    _trtcConn.markLeft();
    TrtcSessionStore.clear();

    // 2) Karşı tarafı bilgilendir + navigasyonu tetikle — ağ temizliğini bekleme.
    if (peerEndedMessage != null) {
      ref.read(psychicPeerLeftProvider.notifier).notifyPeerLeft(
            sessionId: sessionId,
            message: peerEndedMessage,
          );
    }

    if (!silent && ref.read(psychicSessionEndedProvider) == null) {
      ref.read(psychicSessionEndedProvider.notifier).state = PsychicSessionEndedEvent(
        sessionId: sessionId,
        tellerId: session.psychic.id,
        tellerName: session.psychic.name,
        durationMinutes: session.durationMinutes,
        totalJeton: session.totalJeton,
        tipsJeton: !isClient && tipsTotal > 0 ? tipsTotal : null,
        isTeller: !isClient,
        promptReview: isClient,
        navigateAfter: true,
      );
    }

    // 3) Backend temizliği arka planda, her çağrıya zaman aşımı koyarak yürüt.
    //    Herhangi biri takılsa bile UI zaten kapanmış olur.
    unawaited(_cleanupBackend(
      repo: repo,
      sse: sse,
      sessionId: sessionId,
      isClient: isClient,
      endedBy: user?.id,
      tellerReceiver: tellerReceiver,
      clientReceiver: clientReceiver,
    ));

    unawaited(PsychicSessionStore.clear());
    PsychicEventLog.sessionEnd(sessionId: sessionId, reason: 'leave');
    _setPhase(PsychicSessionPhase.ended);
    invalidateWalletCacheFromRef(ref);
  }

  Future<void> _cleanupBackend({
    required LivePsychicsRepository repo,
    required PsychicRoomSseService sse,
    required String sessionId,
    required bool isClient,
    required String? endedBy,
    required String? tellerReceiver,
    required String? clientReceiver,
  }) async {
    const t = Duration(seconds: 4);
    // Karşı tarafa "session_end" sinyalini önce gönder ki SSE ile haber alsın.
    try {
      await repo.roomAction(
        sessionId,
        'end',
        extra: {
          'endedByRole': isClient ? 'client' : 'teller',
          if (endedBy != null) 'endedBy': endedBy,
        },
      ).timeout(t);
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.fortune, 'psychic_video_controller:1833');
    }
    try {
      await repo.clearRoomSignals(sessionId).timeout(t);
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.fortune, 'psychic_video_controller:1836');
    }
    try {
      await sse.disconnect(forSessionId: sessionId).timeout(t);
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.fortune, 'psychic_video_controller:1839');
    }
  }

  Future<UserEntity?> _waitForAuth() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future);
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  void onAppPaused() {
    if (_disposed || state.leaving) return;
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'app_paused',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
    );
  }

  void onAppResumed() {
    if (_disposed || state.leaving) return;
    unawaited(() async {
      final active = await _syncRoomInfo();
      if (_disposed || state.leaving || !active) return;
      await _pollRoomSignals();
      if (_disposed || state.leaving) return;
      if (state.sseFailed || !state.sseConnected) {
        await retryRoomSse();
      }
      if (!state.timerStarted || !state.sseConnected) {
        _scheduleRoomPoll();
      }
      if (!_trtc.inRoom) {
        await _reconnectTrtc(PsychicTrtcReconnectReason.appResumedNotInRoom);
      }
    }());
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'app_resumed',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _roomSyncHttpCancel?.cancel('dispose');
    _roomSyncHttpCancel = null;
    _signalsHttpCancel?.cancel('dispose');
    _signalsHttpCancel = null;
    CfDiagnosticSessionMonitor.transition(
      type: 'LIVE_FORTUNE',
      sessionKey: session.sessionId,
      state: 'ENDED',
    );
    _trtcConn.markDisposed();
    _stopRemoteVideoWatchdog();
    _detachRemoteMediaListeners();
    _cancelPeriodic(_tick, 'session_tick');
    _cancelPeriodic(_chatPoll, 'chat_poll');
    _cancelPeriodic(_ping, 'session_ping');
    _cancelPeriodic(_roomPoll, 'room_poll');
    _cancelPeriodic(_signalPoll, 'signal_poll');
    _sseAutoRetryTimer?.cancel();
    _tipThankYouDismissTimer?.cancel();
    _tipReceivedDismissTimer?.cancel();
    unawaited(_onlineSub?.cancel());
    _onlineSub = null;
    _trtc.onConnectionLost = null;
    unawaited(_roomSse.disconnect(forSessionId: session.sessionId));
    unawaited(_trtc.leave());
    super.dispose();
  }
}

final psychicVideoControllerProvider = StateNotifierProvider.autoDispose
    .family<PsychicVideoController, PsychicVideoState, PsychicSessionEntity>(
  (ref, session) => PsychicVideoController(ref, session),
);
