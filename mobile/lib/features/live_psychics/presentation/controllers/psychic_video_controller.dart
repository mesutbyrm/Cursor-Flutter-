import 'dart:async';

/// Canlı fal video oturumu — **TRTC birincil** medya katmanı.
/// HTTP `/api/room/signal` yalnızca seans bitişinde sinyal temizliği için kullanılır.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_extend_sheet.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_tip_sheet.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';
import 'package:canlifal_social/features/trtc/presentation/providers/trtc_providers.dart';
import 'package:canlifal_social/features/trtc/presentation/trtc_room_manager.dart';

class PsychicVideoState {
  const PsychicVideoState({
    this.rtcReady = false,
    this.rtcError,
    this.messages = const [],
    this.remaining = Duration.zero,
    this.timerStarted = false,
    this.waitingForTimer = false,
    this.leaving = false,
    this.sendingChat = false,
    this.room,
    this.tipThankYouAmount,
    this.sseConnected = false,
    this.localPreviewKey = 0,
    this.timeUpPending = false,
  });

  final bool rtcReady;
  final String? rtcError;
  final List<PsychicChatMessage> messages;
  final Duration remaining;
  final bool timerStarted;
  final bool waitingForTimer;
  final bool leaving;
  final bool sendingChat;
  final PsychicRoomEntity? room;
  final int? tipThankYouAmount;
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
    bool? sseConnected,
    int? localPreviewKey,
    bool? timeUpPending,
  }) {
    return PsychicVideoState(
      rtcReady: rtcReady ?? this.rtcReady,
      rtcError: clearRtcError ? null : (rtcError ?? this.rtcError),
      messages: messages ?? this.messages,
      remaining: remaining ?? this.remaining,
      timerStarted: timerStarted ?? this.timerStarted,
      waitingForTimer: waitingForTimer ?? this.waitingForTimer,
      leaving: leaving ?? this.leaving,
      sendingChat: sendingChat ?? this.sendingChat,
      room: room ?? this.room,
      tipThankYouAmount:
          clearTipThankYou ? null : (tipThankYouAmount ?? this.tipThankYouAmount),
      sseConnected: sseConnected ?? this.sseConnected,
      localPreviewKey: localPreviewKey ?? this.localPreviewKey,
      timeUpPending: timeUpPending ?? this.timeUpPending,
    );
  }
}

class PsychicVideoController extends StateNotifier<PsychicVideoState> {
  PsychicVideoController(this.ref, this.session)
      : super(PsychicVideoState(remaining: Duration(minutes: session.durationMinutes))) {
    _trtc = TrtcRoomManager();
    _bootstrap();
  }

  final Ref ref;
  final PsychicSessionEntity session;

  late final TrtcRoomManager _trtc;
  final _seenChatIds = <String>{};
  String? _lastChatAfter;
  Timer? _tick;
  Timer? _chatPoll;
  Timer? _ping;
  Timer? _roomPoll;
  var _disposed = false;

  TrtcRoomManager get trtc => _trtc;

  String get trtcRoomId {
    final fromRoom = state.room?.roomId?.trim();
    if (fromRoom != null && fromRoom.isNotEmpty) return fromRoom;
    return session.trtcRoomId;
  }

  String get remotePeerId => session.remotePeerIdFor(room: state.room);

  Future<void> _bootstrap() async {
    await PsychicSessionStore.save(session);
    await _syncRoomInfo(startTimerIfTeller: true);
    _startTimers();
    await _joinRtc();
    await _connectRoomSse();
    _startChatPoll();
  }

  void _startTimers() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || state.leaving) return;
      if (!state.timerStarted) return;
      final secs = state.room?.remainingSeconds ?? state.remaining.inSeconds - 1;
      if (secs <= 0) {
        unawaited(_onTimeUp());
        return;
      }
      state = state.copyWith(remaining: Duration(seconds: secs));
    });

    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 60), (_) => _sendPing());

    _roomPoll?.cancel();
    _roomPoll = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_syncRoomInfo());
    });
  }

  Future<void> _syncRoomInfo({bool startTimerIfTeller = false}) async {
    if (_disposed || state.leaving) return;
    final repo = ref.read(livePsychicsRepositoryProvider);
    final previousRoomId = state.room?.roomId;
    final info = await repo.fetchRoom(session.sessionId);
    if (_disposed || info == null) return;

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
      final updated = session.copyWith(
        tellerUserId: room.tellerUserId ?? session.tellerUserId,
        clientId: room.clientId ?? session.clientId,
        trtcRoomIdOverride: newRoomId,
      );
      unawaited(PsychicSessionStore.save(updated));
    }

    if (newRoomId != null &&
        newRoomId.isNotEmpty &&
        previousRoomId != newRoomId &&
        (state.rtcReady || state.rtcError != null)) {
      await _rejoinRtc();
    }
  }

  Future<void> _rejoinRtc() async {
    await _trtc.leave();
    if (_disposed) return;
    state = state.copyWith(rtcReady: false);
    await _joinRtc();
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
    await ref.read(psychicRoomSseServiceProvider).connect(
          sessionId: session.sessionId,
          accessToken: storage.readAccess,
          myUserId: user?.id,
          onConnected: () {
            if (_disposed) return;
            if (!state.sseConnected) {
              state = state.copyWith(sseConnected: true);
              _startChatPoll();
            }
          },
          onMessage: _onSseChatMessage,
          onRoomUpdate: _onSseRoomUpdate,
          onSessionEnded: (_) {
            if (_disposed || state.leaving) return;
            unawaited(leave(silent: true));
          },
        );
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
    final previousRoomId = state.room?.roomId;
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
    if (info.roomId != null &&
        info.roomId!.isNotEmpty &&
        previousRoomId != info.roomId &&
        (state.rtcReady || state.rtcError != null)) {
      unawaited(_rejoinRtc());
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

    await _syncRoomInfo();
    final repo = ref.read(livePsychicsRepositoryProvider);
    final status = await repo.fetchSessionStatus(session.sessionId);
    if (status?.trtcRoomId != null && status!.trtcRoomId!.trim().isNotEmpty) {
      final updated = session.copyWith(
        trtcRoomIdOverride: status.trtcRoomId,
        tellerUserId: status.tellerUserId ?? session.tellerUserId,
      );
      unawaited(PsychicSessionStore.save(updated));
    }

    if (state.room?.roomId == null || state.room!.roomId!.trim().isEmpty) {
      await _syncRoomInfo();
    }
    final roomId = trtcRoomId;
    if (roomId.trim().isEmpty) {
      state = state.copyWith(rtcError: 'Oda bilgisi alınamadı. Tekrar deneyin.');
      return;
    }
    final remotePeerId = this.remotePeerId;
    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: roomId,
          );
      final effectiveRoomId =
          cred.roomId.trim().isNotEmpty ? cred.roomId.trim() : roomId;
      await _trtc.join(
        credentials: TrtcCredentials(
          sdkAppId: cred.sdkAppId,
          userId: cred.userId,
          userSig: cred.userSig,
          roomId: effectiveRoomId,
        ),
        isHost: !session.isClient,
        audioOnly: false,
        twoWayVideo: true,
        expectedAnchorUserId: session.isClient
            ? (remotePeerId.trim().isNotEmpty
                ? remotePeerId.trim()
                : session.anchorUserId)
            : (remotePeerId.trim().isNotEmpty ? remotePeerId.trim() : null),
      );
      state = state.copyWith(rtcReady: true, clearRtcError: true);
    } catch (e) {
      state = state.copyWith(rtcError: ApiException.userMessage(e));
    }
  }

  Future<void> retryRtc() => _rejoinRtc();

  Future<void> sendChat(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.sendingChat) return;
    state = state.copyWith(sendingChat: true);
    final user = ref.read(authControllerProvider).valueOrNull;
    final ok = await ref
        .read(livePsychicsRepositoryProvider)
        .sendMessage(session.sessionId, t);
    state = state.copyWith(sendingChat: false);
    if (ok) {
      final mine = PsychicChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        senderId: user?.id ?? '',
        senderName: 'Sen',
        text: t,
        createdAt: DateTime.now(),
        isMine: true,
      );
      _seenChatIds.add(mine.id);
      state = state.copyWith(messages: [...state.messages, mine]);
    }
    unawaited(_pollChat());
  }

  Future<int?> openTipSheet(BuildContext context) async {
    final balance = ref.read(coinBalanceProvider).valueOrNull ??
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
      ref.invalidate(coinBalanceProvider);
      state = state.copyWith(tipThankYouAmount: amount);
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (!_disposed) state = state.copyWith(clearTipThankYou: true);
      });
    }
    return ok;
  }

  Future<PsychicExtendOption?> openExtendSheet(BuildContext context) async {
    final perMin = session.psychic.pricePerMinute > 0
        ? session.psychic.pricePerMinute
        : 10;
    final isStaff =
        ref.read(walletBalancesProvider).valueOrNull?.isStaff == true;
    final balance = ref.read(coinBalanceProvider).valueOrNull ??
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
      ref.invalidate(coinBalanceProvider);
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
      ref.invalidate(coinBalanceProvider);
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
    _trtc.setMicEnabled(!_trtc.micOn);
  }

  void toggleCamera() {
    _trtc.setCameraEnabled(!_trtc.cameraOn);
    state = state.copyWith(localPreviewKey: state.localPreviewKey + 1);
  }

  void switchCamera() => _trtc.switchCamera();

  Future<void> leave({bool silent = false}) async {
    if (state.leaving) return;
    state = state.copyWith(leaving: true);
    _tick?.cancel();
    _chatPoll?.cancel();
    _ping?.cancel();
    _roomPoll?.cancel();
    await ref.read(psychicRoomSseServiceProvider).disconnect();
    try {
      await ref.read(livePsychicsRepositoryProvider).endSession(session.sessionId);
    } catch (_) {}
    try {
      await ref
          .read(livePsychicsRepositoryProvider)
          .clearRoomSignals(session.sessionId);
    } catch (_) {}
    await _trtc.leave();
    await PsychicSessionStore.clear();
    ref.invalidate(coinBalanceProvider);
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
    unawaited(ref.read(psychicRoomSseServiceProvider).disconnect());
    _trtc.dispose();
    super.dispose();
  }
}

final psychicVideoControllerProvider = StateNotifierProvider.autoDispose
    .family<PsychicVideoController, PsychicVideoState, PsychicSessionEntity>(
  (ref, session) => PsychicVideoController(ref, session),
);
