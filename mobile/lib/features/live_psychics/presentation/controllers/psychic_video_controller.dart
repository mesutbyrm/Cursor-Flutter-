import 'dart:async';

/// Canlı fal video oturumu — Tencent TRTC.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/config/env.dart';
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
    );
  }
}

class PsychicVideoController extends StateNotifier<PsychicVideoState> {
  PsychicVideoController(this.ref, PsychicSessionEntity session)
      : session = session,
        super(PsychicVideoState(remaining: Duration(minutes: session.durationMinutes))) {
    _trtc = ref.read(trtcRoomManagerProvider);
    _trtcConn.sessionId = session.sessionId;
    _watchNetwork();
    _bootstrap();
  }

  final Ref ref;
  PsychicSessionEntity session;

  late final TrtcRoomManager _trtc;
  final _trtcConn = PsychicTrtcConnection();
  final _remoteBind = PsychicTrtcListenerBind();
  final _seenChatIds = <String>{};
  String? _lastChatAfter;
  Timer? _tick;
  Timer? _chatPoll;
  Timer? _ping;
  Timer? _roomPoll;
  Timer? _signalPoll;
  var _disposed = false;
  var _remoteEndHandled = false;
  final _seenSignalIds = <String>{};
  final _seenTipEventIds = <String>{};
  Timer? _sseAutoRetryTimer;
  var _sseAutoRetryCount = 0;
  static const _maxSseAutoRetry = 3;
  StreamSubscription<bool>? _onlineSub;

  VoidCallback? _remoteVideoListener;
  VoidCallback? _remoteAudioListener;

  void _setPhase(PsychicSessionPhase next) {
    final from = state.phase;
    final allowed = PsychicSessionPhaseGuard.transition(from, next);
    if (allowed == null) return;
    PsychicEventLog.phase(from.name, allowed.name, sessionId: session.sessionId);
    state = state.copyWith(phase: allowed);
  }

  void _attachRemoteMediaListeners() {
    if (!_remoteBind.tryAttach()) return;
    _remoteVideoListener ??= () {
      if (_disposed) return;
      final map = Map<String, bool>.from(_trtc.remoteVideoByUser.value);
      state = state.copyWith(remoteCamera: map);
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
    _trtc.remoteVideoByUser.addListener(_remoteVideoListener!);
    _trtc.remoteAudioByUser.addListener(_remoteAudioListener!);
  }

  void _detachRemoteMediaListeners() {
    if (!_remoteBind.tryDetach()) return;
    if (_remoteVideoListener != null) {
      _trtc.remoteVideoByUser.removeListener(_remoteVideoListener!);
    }
    if (_remoteAudioListener != null) {
      _trtc.remoteAudioByUser.removeListener(_remoteAudioListener!);
    }
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
    await _waitForRoomBootstrap();
    if (_disposed || state.leaving) return;
    await _joinRtc();
    await _connectRoomSse();
    _startChatPoll();
  }

  /// Peer kimliği için oda bilgisi — TRTC join sessionId ile kilitlenir.
  Future<void> _waitForRoomBootstrap() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      await _syncRoomInfo();
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

  /// Falcı manuel olarak süreyi başlatır (kılavuz §11.1).
  Future<bool> startTimer() async {
    if (_disposed || state.leaving || state.timerStarted || session.isClient) {
      return false;
    }
    await _ensureTimerStarted();
    return state.timerStarted;
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
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || state.leaving) return;
      if (!state.timerStarted) return;
      final room = state.room;
      final secs = room != null && room.timerStarted
          ? room.remainingSeconds
          : state.remaining.inSeconds - 1;
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
    });

    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 60), (_) => _sendPing());

    _scheduleRoomPoll();
    _scheduleSignalPoll();
  }

  void _scheduleSignalPoll() {
    _signalPoll?.cancel();
    if (_disposed) return;
    // SSE bağlıyken oturum sonu / bahşiş SSE'den gelir; sinyal poll yalnızca
    // media_state (RTC) için yedek — daha seyrek.
    final interval = state.sseConnected
        ? const Duration(seconds: 30)
        : const Duration(seconds: 3);
    _signalPoll = Timer.periodic(interval, (_) {
      unawaited(_pollRoomSignals());
    });
    unawaited(_pollRoomSignals());
  }

  void _scheduleRoomPoll() {
    _roomPoll?.cancel();
    if (_disposed || state.sseConnected) return;
    final interval = state.sseConnected
        ? const Duration(seconds: 20)
        : const Duration(seconds: 3);
    _roomPoll = Timer.periodic(interval, (_) {
      unawaited(_syncRoomInfo());
    });
  }

  Future<void> _pollRoomSignals() async {
    if (_disposed || state.leaving) return;
    final repo = ref.read(livePsychicsRepositoryProvider);
    final signals = await repo.fetchRoomSignals(session.sessionId);
    if (_disposed) return;
    for (final sig in signals) {
      final id = sig['id']?.toString() ??
          '${sig['type']}_${sig['createdAt'] ?? sig['timestamp']}';
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
      if (!session.isClient &&
          (type.contains('tip') ||
              type.contains('bahsis') ||
              type.contains('gift') ||
              type.contains('hediye'))) {
        final data = sig['data'] is Map
            ? Map<String, dynamic>.from(sig['data'] as Map)
            : sig;
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

  Future<void> _syncRoomInfo() async {
    if (_disposed || state.leaving) return;
    final repo = ref.read(livePsychicsRepositoryProvider);
    final info = await repo.fetchRoom(session.sessionId);
    if (_disposed || info == null) return;

    if (info.status == PsychicSessionStatus.cancelled ||
        info.status == PsychicSessionStatus.rejected ||
        info.status == PsychicSessionStatus.ended ||
        info.status == PsychicSessionStatus.expired) {
      unawaited(_handleRemoteSessionEnded(info.status));
      return;
    }

    final statusResult = await repo.fetchSessionStatus(session.sessionId);
    if (_disposed) return;
    if (statusResult != null &&
        (statusResult.status == PsychicSessionStatus.cancelled ||
            statusResult.status == PsychicSessionStatus.rejected ||
            statusResult.status == PsychicSessionStatus.ended ||
            statusResult.status == PsychicSessionStatus.expired)) {
      unawaited(_handleRemoteSessionEnded(statusResult.status));
      return;
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

    if (room.tellerUserId != null || room.clientId != null) {
      session = session.copyWith(
        tellerUserId: room.tellerUserId ?? session.tellerUserId,
        clientId: room.clientId ?? session.clientId,
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
  }

  Future<void> _sendPing() async {
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
    _chatPoll?.cancel();
    if (_disposed || state.sseConnected) return;
    const interval = Duration(seconds: 3);
    _chatPoll = Timer.periodic(interval, (_) => unawaited(_pollChat()));
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
              _chatPoll?.cancel();
              _roomPoll?.cancel();
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
          onTipReceived: (amount, fromName) {
            if (_disposed || state.leaving) return;
            _onTipReceived(amount, fromName, eventId: 'sse-$amount-$fromName');
          },
        );
  }

  void _onTipReceived(int amount, String? fromName, {String? eventId}) {
    if (amount <= 0) return;
    final id = eventId?.trim();
    if (id != null && id.isNotEmpty && !_seenTipEventIds.add(id)) return;

    // Danışan yalnızca kendi gönderim teşekkürünü görür; falcı SSE/sinyal popup alır.
    if (session.isClient) return;

    final total = state.sessionTipsTotal + amount;
    state = state.copyWith(
      tipReceivedAmount: amount,
      tipReceivedFrom: fromName,
      sessionTipsTotal: total,
    );
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!_disposed) state = state.copyWith(clearTipReceived: true);
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
    if (info.roomId != null &&
        info.roomId!.isNotEmpty &&
        _trtcConn.joinedTrtcRoomId != null) {
      _logSkipRejoin(info.roomId!);
    }
  }

  Future<void> _pollChat() async {
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
    return session.sessionId.trim();
  }

  Future<void> _joinTrtc({required UserEntity user}) async {
    if (!_trtcConn.tryBeginJoin()) return;
    _setPhase(PsychicSessionPhase.joining);
    final requestRoomId = _tokenRequestRoomId();
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

      final creds = await ref.read(trtcRemoteProvider).fetchToken(
            roomId: requestRoomId,
            role: session.isClient ? 'audience' : 'host',
            userId: user.id,
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

      await _trtc.join(
        credentials: creds,
        isHost: !session.isClient,
        twoWayVideo: true,
        expectedAnchorUserId: session.remotePeerIdFor(room: state.room),
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
      unawaited(_broadcastMediaState());
      if (!session.isClient && !state.timerStarted) {
        unawaited(_ensureTimerStarted());
      }
    } catch (e) {
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
    state = state.copyWith(sendingChat: true);
    try {
      final ok = await ref
          .read(livePsychicsRepositoryProvider)
          .sendMessage(session.sessionId, t);
      if (!ok && !_disposed) {
        state = state.copyWith(sendingChat: false);
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
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!_disposed) state = state.copyWith(clearTipThankYou: true);
      });
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

  void switchCamera() => _trtc.switchCamera();

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
    } catch (_) {}
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
    } catch (_) {}
    try {
      await repo.clearRoomSignals(sessionId).timeout(t);
    } catch (_) {}
    try {
      await sse.disconnect().timeout(t);
    } catch (_) {}
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
    if (state.sseFailed || !state.sseConnected) {
      unawaited(retryRoomSse());
    }
    PsychicEventLog.trtcState(
      sessionId: session.sessionId,
      connectionState: 'app_resumed',
      roomId: _trtcConn.tokenRequestRoomId,
      trtcRoomId: _trtcConn.joinedTrtcRoomId,
      userId: _trtcConn.joinedUserId,
      inRoom: _trtc.inRoom,
    );
    if (!_trtc.inRoom) {
      unawaited(
        _reconnectTrtc(PsychicTrtcReconnectReason.appResumedNotInRoom),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _trtcConn.markDisposed();
    _detachRemoteMediaListeners();
    _tick?.cancel();
    _chatPoll?.cancel();
    _ping?.cancel();
    _roomPoll?.cancel();
    _signalPoll?.cancel();
    _sseAutoRetryTimer?.cancel();
    unawaited(_onlineSub?.cancel());
    _onlineSub = null;
    _trtc.onConnectionLost = null;
    unawaited(ref.read(psychicRoomSseServiceProvider).disconnect());
    unawaited(_trtc.leave());
    super.dispose();
  }
}

final psychicVideoControllerProvider = StateNotifierProvider.autoDispose
    .family<PsychicVideoController, PsychicVideoState, PsychicSessionEntity>(
  (ref, session) => PsychicVideoController(ref, session),
);
