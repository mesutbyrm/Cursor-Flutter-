import 'dart:async';

/// Canlı fal video oturumu — **Agora** (canlı yayın ile aynı altyapı).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/live_debug_log.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/agora/domain/agora_channel_names.dart';
import 'package:canlifal_social/features/agora/presentation/agora_room_manager.dart';
import 'package:canlifal_social/features/agora/presentation/providers/agora_providers.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_beauty_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_extend_sheet.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_tip_sheet.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_peer_left_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_ended_provider.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';

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
    this.tipReceivedAmount,
    this.tipReceivedFrom,
    this.sessionTipsTotal = 0,
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
  PsychicVideoController(this.ref, this.session)
      : super(PsychicVideoState(remaining: Duration(minutes: session.durationMinutes))) {
    _agora = AgoraRoomManager();
    _bootstrap();
  }

  final Ref ref;
  final PsychicSessionEntity session;

  late final AgoraRoomManager _agora;
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

  AgoraRoomManager get agora => _agora;

  String get channelId {
    final fromRoom = state.room?.roomId?.trim();
    final raw = (fromRoom != null && fromRoom.isNotEmpty)
        ? fromRoom
        : session.trtcRoomId;
    return AgoraChannelNames.forRoom(raw);
  }

  Future<void> _bootstrap() async {
    LiveDebugLog.log('psychic.session.bootstrap', {
      'sessionId': session.sessionId,
      'isClient': session.isClient,
    });
    await PsychicSessionStore.save(session);
    _startTimers();
    unawaited(_syncRoomInfo(startTimerIfTeller: true));
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

    _roomPoll?.cancel();
    _roomPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_syncRoomInfo());
    });

    _signalPoll?.cancel();
    if (!session.isClient) {
      _signalPoll = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_pollRoomSignals());
      });
      unawaited(_pollRoomSignals());
    }
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
      if (!type.contains('tip') && !type.contains('bahsis')) continue;
      final data = sig['data'] is Map
          ? Map<String, dynamic>.from(sig['data'] as Map)
          : sig;
      final amountRaw = data['amount'] ??
          data['jeton'] ??
          data['tipAmount'] ??
          data['value'] ??
          sig['amount'];
      final amount = amountRaw is num
          ? amountRaw.round()
          : int.tryParse('$amountRaw') ?? 0;
      final from = data['fromName']?.toString() ??
          data['senderName']?.toString() ??
          data['from']?.toString();
      _onTipReceived(amount, from);
    }
  }

  Future<void> _syncRoomInfo({bool startTimerIfTeller = false}) async {
    if (_disposed || state.leaving) return;
    final repo = ref.read(livePsychicsRepositoryProvider);
    final previousRoomId = state.room?.roomId;
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
    await _agora.leave();
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
          onSessionEnded: (status) {
            if (_disposed || state.leaving) return;
            unawaited(_handleRemoteSessionEnded(status));
          },
          onTipReceived: (amount, fromName) {
            if (_disposed || state.leaving) return;
            _onTipReceived(amount, fromName);
          },
        );
  }

  void _onTipReceived(int amount, String? fromName) {
    if (amount <= 0) return;
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
    if (!_agora.isSupported) {
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
    final roomId = channelId;
    if (roomId.trim().isEmpty) {
      state = state.copyWith(rtcError: 'Oda bilgisi alınamadı. Tekrar deneyin.');
      return;
    }

    LiveDebugLog.log('psychic.agora.join.request', {
      'sessionId': session.sessionId,
      'channel': roomId,
      'userId': user.id,
    });

    try {
      final cred = await ref.read(agoraRemoteProvider).fetchToken(
            channelName: roomId,
            role: 'host',
          );
      final effectiveChannel = cred.channelName.trim().isNotEmpty
          ? cred.channelName.trim()
          : roomId;

      await _agora.joinTwoWayVideo(
        credentials: cred.copyWith(channelName: effectiveChannel),
      );
      ref.read(liveBeautyProvider.notifier).bindRtc(agora: _agora);
      LiveDebugLog.log('psychic.agora.join.ok', {
        'sessionId': session.sessionId,
        'channel': effectiveChannel,
        'uid': cred.uid,
      });
      state = state.copyWith(rtcReady: true, clearRtcError: true);
      if (!session.isClient && !state.timerStarted) {
        unawaited(_ensureTimerStarted());
      }
    } catch (e) {
      LiveDebugLog.log('psychic.agora.join.fail', {
        'sessionId': session.sessionId,
        'channel': roomId,
        'error': ApiException.userMessage(e),
      });
      state = state.copyWith(rtcError: ApiException.userMessage(e));
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
      final tellerUid = session.tellerUserId ?? state.room?.tellerUserId;
      unawaited(
        ref.read(livePsychicsRepositoryProvider).sendRoomSignal(
              sessionId: session.sessionId,
              type: 'tip',
              data: {
                'amount': amount,
                'senderName': ref.read(authControllerProvider).valueOrNull?.display,
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

  void toggleMic() {
    _agora.setMicEnabled(!_agora.micOn);
  }

  void toggleCamera() {
    _agora.setCameraEnabled(!_agora.cameraOn);
    state = state.copyWith(localPreviewKey: state.localPreviewKey + 1);
  }

  void switchCamera() => _agora.switchCamera();

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
    ref.read(psychicSessionCancelSignalProvider.notifier).signal(session.sessionId);
    final user = ref.read(authControllerProvider).valueOrNull;
    final tipsTotal = state.sessionTipsTotal;
    final sessionId = session.sessionId;
    final isClient = session.isClient;
    final repo = ref.read(livePsychicsRepositoryProvider);

    // Karşı tarafa önce sinyal gönder — RTC kapanmadan SSE ile haber ver.
    try {
      await repo.sendRoomSignal(
        sessionId: sessionId,
        type: 'session_end',
        data: {
          'endedByRole': isClient ? 'client' : 'teller',
          if (user?.id != null) 'endedBy': user!.id,
        },
        receiverId: isClient
            ? (state.room?.tellerUserId ?? session.tellerUserId)
            : state.room?.clientId,
      );
    } catch (_) {}
    try {
      await repo.roomAction(
        sessionId,
        'end',
        extra: {
          'endedByRole': isClient ? 'client' : 'teller',
          if (user?.id != null) 'endedBy': user!.id,
        },
      );
    } catch (_) {}
    try {
      await repo.endSession(sessionId);
    } catch (_) {}
    try {
      await repo.clearRoomSignals(sessionId);
    } catch (_) {}

    try {
      await _agora.leave();
    } catch (_) {}
    try {
      await ref.read(psychicRoomSseServiceProvider).disconnect();
    } catch (_) {}
    await PsychicSessionStore.clear();

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

    invalidateWalletCacheFromRef(ref);
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
    _agora.dispose();
    super.dispose();
  }
}

final psychicVideoControllerProvider = StateNotifierProvider.autoDispose
    .family<PsychicVideoController, PsychicVideoState, PsychicSessionEntity>(
  (ref, session) => PsychicVideoController(ref, session),
);
