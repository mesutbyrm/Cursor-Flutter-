import 'dart:async';

/// Canlı fal video oturumu — Tencent TRTC.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/config/env.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/dio_provider.dart';
import 'package:canlifal_social/core/network/live_debug_log.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_beauty_provider.dart';
import 'package:canlifal_social/features/trtc/presentation/providers/trtc_providers.dart';
import 'package:canlifal_social/features/trtc/presentation/trtc_live_room_coordinator.dart';
import 'package:canlifal_social/features/trtc/presentation/trtc_room_manager.dart';
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
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';

enum PsychicRtcBackend { none, trtc }

class PsychicVideoState {
  const PsychicVideoState({
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
  });

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

  String get timerLabel {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  PsychicVideoState copyWith({
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
  }) {
    return PsychicVideoState(
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
    );
  }
}

class PsychicVideoController extends StateNotifier<PsychicVideoState> {
  PsychicVideoController(this.ref, PsychicSessionEntity session)
      : session = session,
        super(PsychicVideoState(remaining: Duration(minutes: session.durationMinutes))) {
    _trtc = ref.read(trtcRoomManagerProvider);
    _bootstrap();
  }

  final Ref ref;
  PsychicSessionEntity session;

  late final TrtcRoomManager _trtc;
  TrtcLiveRoomCoordinator? _trtcCoordinator;
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
  String? _joinedTrtcRoom;
  var _rejoiningRtc = false;

  TrtcRoomManager get trtc => _trtc;
  bool get micOn => _trtc.micOn;
  bool get cameraOn => _trtc.cameraOn;

  String get channelId {
    final fromRoom = state.room?.roomId?.trim();
    final raw = (fromRoom != null && fromRoom.isNotEmpty)
        ? fromRoom
        : session.trtcRoomId;
    return raw.trim();
  }

  Future<void> _bootstrap() async {
    LiveDebugLog.log('psychic.session.bootstrap', {
      'sessionId': session.sessionId,
      'isClient': session.isClient,
    });
    await PsychicSessionStore.save(session);
    _startTimers();
    await _syncRoomInfo(startTimerIfTeller: true);
    await Future.wait([
      _joinRtc(),
      _connectRoomSse(),
    ]);
    _startChatPoll();
    if (!session.isClient && !state.timerStarted) {
      unawaited(_ensureTimerStarted());
    }
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
      state = state.copyWith(remaining: Duration(seconds: secs));
    });

    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 60), (_) => _sendPing());

    _scheduleRoomPoll();

    _signalPoll?.cancel();
    if (!session.isClient) {
      _signalPoll = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_pollRoomSignals());
      });
      unawaited(_pollRoomSignals());
    }
  }

  void _scheduleRoomPoll() {
    _roomPoll?.cancel();
    if (_disposed) return;
    final interval = state.sseConnected
        ? const Duration(seconds: 20)
        : const Duration(seconds: 3);
    _roomPoll = Timer.periodic(interval, (_) {
      unawaited(_syncRoomInfo());
    });
  }

  Future<void> _pollRoomSignals() async {
    if (_disposed || state.leaving || session.isClient) return;
    final repo = ref.read(livePsychicsRepositoryProvider);
    final signals = await repo.fetchRoomSignals(session.sessionId);
    if (_disposed) return;
    for (final sig in signals) {
      final id = sig['id']?.toString() ??
          '${sig['type']}_${sig['createdAt'] ?? sig['timestamp']}';
      if (id.isEmpty || !_seenSignalIds.add(id)) continue;
      final type = (sig['type'] ?? '').toString().toLowerCase();
      if (!type.contains('tip') &&
          !type.contains('bahsis') &&
          !type.contains('gift') &&
          !type.contains('hediye')) continue;
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

  Future<void> _syncRoomInfo({bool startTimerIfTeller = false}) async {
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

    if (startTimerIfTeller && !session.isClient && !info.timerStarted) {
      final result = await repo.roomAction(session.sessionId, 'start_timer');
      if (result != null) {
        final startedAtRaw = result['timerStartedAt']?.toString();
        final startedAt = startedAtRaw != null
            ? DateTime.tryParse(startedAtRaw)
            : DateTime.now();
        final room = info.copyWith(
          timerStarted: true,
          timerStartedAt: startedAt,
          maxMinutes: maxMinutes,
        );
        state = state.copyWith(
          room: room,
          timerStarted: true,
          waitingForTimer: false,
          remaining: Duration(seconds: room.remainingSeconds),
        );
        return;
      }
    }

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

    final newRoomId = room.roomId;
    if (newRoomId != null && newRoomId.isNotEmpty) {
      session = session.copyWith(
        tellerUserId: room.tellerUserId ?? session.tellerUserId,
        clientId: room.clientId ?? session.clientId,
        trtcRoomIdOverride: newRoomId,
      );
      unawaited(PsychicSessionStore.save(session));
    }

    // Yalnızca gerçekten farklı bir KANALA geçildiyse yeniden bağlan. Ham oda
    // kimliği null'dan gerçek değere dönse bile normalize kanal aynıysa
    // (room_{sessionId}) gereksiz yeniden bağlanma yapıp gecikme yaratma.
    if (newRoomId != null && newRoomId.isNotEmpty) {
      final joined = _joinedTrtcRoom;
      if (joined != null &&
          _canonicalRoomChannel(newRoomId) != _canonicalRoomChannel(joined) &&
          (state.rtcReady || state.rtcError != null)) {
        await _rejoinRtc();
      }
    }
  }

  String _canonicalRoomChannel(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isEmpty) return session.sessionId.trim();
    final base = session.sessionId.trim();
    if (id == base || id == 'room_$base') return base;
    if (id.startsWith('room_')) return id.substring(5);
    return id;
  }

  Future<void> _rejoinRtc() async {
    if (_disposed || state.leaving || _rejoiningRtc) return;
    final roomId = _activeTrtcRoomId();
    if (roomId.isEmpty) return;
    if (_canonicalRoomChannel(_joinedTrtcRoom) ==
            _canonicalRoomChannel(roomId) &&
        state.rtcReady) {
      return;
    }

    _rejoiningRtc = true;
    _joinedTrtcRoom = null;
    state = state.copyWith(rtcReady: false, clearRtcError: true);
    try {
      final user = await _waitForAuth();
      if (user == null) {
        state = state.copyWith(rtcError: 'Oturum için giriş gerekli');
        return;
      }
      if (_trtc.inRoom) {
        await _trtc.leave();
      }
      await _trtcCoordinator?.leave();
      _trtcCoordinator?.dispose();
      _trtcCoordinator = createTrtcLiveRoomCoordinator(ref);
      await _trtcCoordinator!.join(
        roomId: roomId,
        roomType: 'stream',
        userId: user.id,
        isHost: !session.isClient,
        twoWayVideo: true,
        expectedAnchorUserId: session.remotePeerIdFor(room: state.room),
      );
      _joinedTrtcRoom = roomId;
      ref.read(liveBeautyProvider.notifier).bindRtc(trtc: _trtc);
      state = state.copyWith(rtcReady: true, clearRtcError: true);
    } catch (e) {
      state = state.copyWith(rtcError: ApiException.userMessage(e));
    } finally {
      _rejoiningRtc = false;
    }
  }

  String _activeTrtcRoomId() {
    final fromRoom = state.room?.roomId?.trim();
    if (fromRoom != null && fromRoom.isNotEmpty) return fromRoom;
    return session.trtcRoomId.trim();
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
    final interval = state.sseConnected
        ? const Duration(seconds: 20)
        : const Duration(seconds: 3);
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
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true);
              _startChatPoll();
              _scheduleRoomPoll();
            }
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
    }
    state = state.copyWith(
      room: info,
      timerStarted: info.timerStarted,
      waitingForTimer: session.isClient && !info.timerStarted,
      remaining: remaining,
    );
    if (info.roomId != null && info.roomId!.isNotEmpty) {
      final newRoomId = info.roomId!;
      final joined = _joinedTrtcRoom;
      if (joined != null &&
          _canonicalRoomChannel(newRoomId) != _canonicalRoomChannel(joined) &&
          (state.rtcReady || state.rtcError != null)) {
        unawaited(_rejoinRtc());
      }
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

    final trtcRoomId = _activeTrtcRoomId();
    if (trtcRoomId.isEmpty) {
      state = state.copyWith(rtcError: 'Oda bilgisi alınamadı. Tekrar deneyin.');
      return;
    }

    await _joinTrtc(user: user, roomId: trtcRoomId);
  }

  Future<void> _joinTrtc({
    required UserEntity user,
    required String roomId,
  }) async {
    LiveDebugLog.log('psychic.trtc.join.request', {
      'sessionId': session.sessionId,
      'roomId': roomId,
      'userId': user.id,
    });

    _trtcCoordinator?.dispose();
    _trtcCoordinator = createTrtcLiveRoomCoordinator(ref);

    if (_trtc.inRoom) {
      await _trtc.leave();
    }

    await _trtcCoordinator!.join(
      roomId: roomId,
      roomType: 'stream',
      userId: user.id,
      isHost: !session.isClient,
      twoWayVideo: true,
      expectedAnchorUserId: session.remotePeerIdFor(room: state.room),
    );

    _joinedTrtcRoom = roomId;
    ref.read(liveBeautyProvider.notifier).bindRtc(trtc: _trtc);
    LiveDebugLog.log('psychic.trtc.join.ok', {
      'sessionId': session.sessionId,
      'roomId': roomId,
    });
    state = state.copyWith(
      rtcReady: true,
      rtcBackend: PsychicRtcBackend.trtc,
      clearRtcError: true,
    );
    if (!session.isClient && !state.timerStarted) {
      unawaited(_ensureTimerStarted());
    }
  }

  Future<void> retryRtc() => _rejoinRtc();

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
          totalJeton: choice.jeton,
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

  void toggleMic() => _trtc.setMicEnabled(!_trtc.micOn);

  void toggleCamera() {
    _trtc.setCameraEnabled(!_trtc.cameraOn);
    state = state.copyWith(localPreviewKey: state.localPreviewKey + 1);
  }

  void switchCamera() => _trtc.switchCamera();

  Future<void> leave({
    bool silent = false,
    String? peerEndedMessage,
  }) async {
    if (state.leaving) return;
    state = state.copyWith(leaving: true);
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

    // 1) RTC'yi HEMEN kapat — ekranın kapanması backend'e bağlı kalmasın.
    //    (Önceki sürümde ardışık ağ çağrıları takılırsa seans "kapanmıyordu".)
    unawaited(() async {
      try {
        await _trtcCoordinator?.leave();
      } catch (_) {}
    }());

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
      await repo.sendRoomSignal(
        sessionId: sessionId,
        type: 'session_end',
        data: {
          'endedByRole': isClient ? 'client' : 'teller',
          if (endedBy != null) 'endedBy': endedBy,
        },
        receiverId: isClient ? tellerReceiver : clientReceiver,
      ).timeout(t);
    } catch (_) {}
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
      await repo.endSession(sessionId).timeout(t);
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

  void onAppResumed() {
    if (!_disposed && !state.leaving && !state.rtcReady && state.rtcError == null) {
      unawaited(_rejoinRtc());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _chatPoll?.cancel();
    _ping?.cancel();
    _roomPoll?.cancel();
    _signalPoll?.cancel();
    unawaited(ref.read(psychicRoomSseServiceProvider).disconnect());
    unawaited(_trtcCoordinator?.leave());
    _trtcCoordinator?.dispose();
    _trtcCoordinator = null;
    if (_trtc.inRoom) {
      unawaited(_trtc.leave());
    }
    super.dispose();
  }
}

final psychicVideoControllerProvider = StateNotifierProvider.autoDispose
    .family<PsychicVideoController, PsychicVideoState, PsychicSessionEntity>(
  (ref, session) => PsychicVideoController(ref, session),
);
