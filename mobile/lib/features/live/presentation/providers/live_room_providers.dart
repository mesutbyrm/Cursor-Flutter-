import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/network/live_event_log.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../../core/network/sse/sse_hub_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../domain/live_guest_layout_resolver.dart';
import '../../domain/entities/live_fortune_request_entity.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/utils/live_chat_guard.dart';
import '../widgets/broadcast_room/live_room_chat_message.dart';
import '../../data/services/live_namespace_socket_service.dart';
import 'live_providers.dart';
import 'live_stream_engagement_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/domain/gift_system_message.dart';
import '../../../gifts/domain/session_summary_message.dart';
import '../../../gifts/domain/session_gift_summary.dart';
import '../../../gifts/presentation/sync/gift_sse_dispatch.dart';
import '../../../gifts/presentation/sync/gift_sync_log.dart';
import '../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../voice_hub/presentation/providers/voice_recent_gifts_provider.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../../../voice_hub/presentation/utils/voice_staff_chat_style.dart';
import '../../../voice_hub/domain/voice_official_join.dart';
import '../../../voice_hub/domain/entities/chat_room_message.dart';
import '../gifts/providers/live_gift_providers.dart';
import 'live_fortune_request_provider.dart';
import 'live_broadcast_settings_provider.dart';
import 'live_gift_leaderboard_provider.dart';
import 'live_room_interaction_provider.dart';
import 'live_video_pk_provider.dart';
import 'live_namespace_providers.dart';
import 'co_broadcast_provider.dart';
import 'live_guest_grid_provider.dart';
import 'pk_room_providers.dart';
import 'live_pk_streams_provider.dart';
import 'live_pk_invite_signal_provider.dart';

class LiveRoomState {
  const LiveRoomState({
    this.messages = const [],
    this.viewerCount = 0,
    this.streamEnded = false,
    this.sending = false,
    this.sseConnected = false,
    this.error,
    this.fortuneAnsweredNotice,
    this.lastJoinedDisplayName,
  });

  final List<LiveRoomChatMessage> messages;
  final int viewerCount;
  final bool streamEnded;
  final bool sending;
  final bool sseConnected;
  final String? error;
  final String? fortuneAnsweredNotice;
  /// Son yayına giren izleyici — bir sonraki girişe kadar gösterilir.
  final String? lastJoinedDisplayName;

  LiveRoomState copyWith({
    List<LiveRoomChatMessage>? messages,
    int? viewerCount,
    bool? streamEnded,
    bool? sending,
    bool? sseConnected,
    String? error,
    String? fortuneAnsweredNotice,
    String? lastJoinedDisplayName,
    bool clearError = false,
    bool clearFortuneNotice = false,
    bool clearLastJoined = false,
  }) {
    return LiveRoomState(
      messages: messages ?? this.messages,
      viewerCount: viewerCount ?? this.viewerCount,
      streamEnded: streamEnded ?? this.streamEnded,
      sending: sending ?? this.sending,
      sseConnected: sseConnected ?? this.sseConnected,
      error: clearError ? null : (error ?? this.error),
      fortuneAnsweredNotice: clearFortuneNotice
          ? null
          : (fortuneAnsweredNotice ?? this.fortuneAnsweredNotice),
      lastJoinedDisplayName: clearLastJoined
          ? null
          : (lastJoinedDisplayName ?? this.lastJoinedDisplayName),
    );
  }
}

class LiveRoomController extends AutoDisposeFamilyNotifier<LiveRoomState, String> {
  Timer? _poll;
  final Set<String> _seenIds = {};
  LiveNamespaceSocketService? _liveSocket;
  var _tearDownDone = false;
  var _swipeSuspended = false;

  /// Idempotent çıkış — SSE, socket, hediye poll ve backend leave.
  Future<void> tearDownSession() async {
    if (_tearDownDone) return;
    _tearDownDone = true;
    _swipeSuspended = false;
    final streamId = arg;
    _poll?.cancel();
    _poll = null;
    try {
      _liveSocket?.disconnect();
    } catch (_) {}
    _liveSocket = null;
    ref.read(liveGiftRealtimeProvider).setSseActive(false);
    ref.read(liveGiftRealtimeProvider).stop();
    ref.read(liveGiftRealtimeProvider).resetDedupeState();
    ref.read(sseConnectionHubProvider).releaseVideoStream(streamId);
    try {
      await ref.read(liveRemoteProvider).leaveVideoStream(streamId);
    } catch (_) {}
    state = state.copyWith(sseConnected: false, streamEnded: true);
  }

  /// Swipe feed — ekran dışına kayınca TRTC/SSE/presence yükünü bırak; geri dönünce devam.
  Future<void> suspendForSwipe() async {
    if (_tearDownDone || _swipeSuspended) return;
    _swipeSuspended = true;
    _poll?.cancel();
    _poll = null;
    try {
      _liveSocket?.disconnect();
    } catch (_) {}
    _liveSocket = null;
    ref.read(liveGiftRealtimeProvider).setSseActive(false);
    ref.read(liveGiftRealtimeProvider).stop();
    ref.read(sseConnectionHubProvider).releaseVideoStream(arg);
    try {
      await ref.read(liveRemoteProvider).leaveVideoStream(arg);
    } catch (_) {}
    state = state.copyWith(sseConnected: false);
  }

  Future<void> resumeFromSwipe() async {
    if (_tearDownDone || !_swipeSuspended) return;
    _swipeSuspended = false;
    state = state.copyWith(streamEnded: false, clearError: true);
    await _bootstrap(arg);
  }

  @override
  LiveRoomState build(String streamId) {
    ref.onDispose(() {
      unawaited(tearDownSession());
    });
    Future.microtask(() => _bootstrap(streamId));
    return const LiveRoomState();
  }

  Future<void> _bootstrap(String streamId) async {
    try {
      final remote = ref.read(liveRemoteProvider);
      final boot = await NetworkPerf.parallel([
        remote.joinVideoStream(streamId),
        remote.fetchStreamMessages(streamId),
      ]);
      state = state.copyWith(viewerCount: boot[0] as int, clearError: true);
      _mergeMessages(boot[1] as List<LiveStreamChatMessage>);
      _startRealtime(streamId);
      _poll = Timer.periodic(const Duration(seconds: 20), (_) async {
        if (state.streamEnded) return;
        try {
          if (!state.sseConnected) {
            final poll = await NetworkPerf.parallel([
              remote.fetchStreamMessages(streamId),
              remote.fetchStream(streamId),
            ]);
            _mergeMessages(poll[0] as List<LiveStreamChatMessage>);
            final meta = poll[1] as LiveStreamEntity?;
            if (meta != null && !meta.isLive) {
              state = state.copyWith(streamEnded: true);
            }
          } else {
            final meta = await remote.fetchStream(streamId);
            if (meta != null && !meta.isLive) {
              state = state.copyWith(streamEnded: true);
            }
          }
        } catch (_) {}
      });
    } catch (e) {
      state = state.copyWith(error: ApiException.userMessage(e));
    }
  }

  void _startRealtime(String streamId) {
    final storage = ref.read(tokenStorageProvider);
    final hub = ref.read(sseConnectionHubProvider);
    hub.attachVideoStream(streamId);
    final sse = hub.videoStream(streamId);

    sse.connect(
      streamId: streamId,
      accessToken: storage.readAccess,
      onConnected: () {
        state = state.copyWith(sseConnected: true);
        ref.read(liveGiftRealtimeProvider).setSseActive(true);
        GiftSyncLog.broadcast(streamId, 'sse', 'connected');
        GiftSyncLog.sseConnected(streamId);
        LiveDebugLog.log('stream.room.sse_ok', {'streamId': streamId});
      },
      onViewerCount: (count) {
        if (count >= 0) state = state.copyWith(viewerCount: count);
      },
      onMessage: (msg) => _mergeMessages([msg]),
      onGift: (payload) {
        dispatchGiftSsePayloadRef(
          ref: ref,
          sessionKey: streamId,
          payload: payload,
          giftsRemote: ref.read(liveGiftsRemoteProvider),
          voiceRealtime: false,
        );
      },
      onStreamEnded: () {
        state = state.copyWith(streamEnded: true);
        ref.invalidate(livePkStreamsProvider);
      },
      onPkBattle: (battle) {
        ref.read(liveVideoPkProvider(streamId).notifier).applyRemoteBattle(battle);
        final status = (battle['status'] ?? '').toString().toLowerCase();
        if (status == 'pending' || status == 'invited') {
          ref.read(livePkInviteSignalProvider.notifier).bump();
          ref.invalidate(pkPendingInvitesProvider);
        }
      },
      onLike: (count) {
        ref
            .read(liveRoomInteractionProvider(streamId).notifier)
            .syncRemoteLikeCount(count);
      },
      onUserJoined: (user) {
        final count = user['viewerCount'] ?? user['viewers'] ?? user['watching'];
        final name = (user['displayName'] ??
                user['name'] ??
                user['username'] ??
                user['nickname'] ??
                user['userName'] ??
                '')
            .toString()
            .trim();
        final joinId = (user['id'] ?? user['userId'] ?? name).toString();
        var next = state;
        if (count is num) {
          next = next.copyWith(viewerCount: count.round());
        }
        if (name.isNotEmpty) {
          final userRef = ChatRoomUserRef(
            id: joinId,
            name: name,
            nickname: user['nickname']?.toString(),
            membership: user['membership']?.toString() ??
                user['tier']?.toString() ??
                user['vipTier']?.toString(),
            chatRole: user['chatRole']?.toString() ?? user['role']?.toString(),
          );
          if (VoiceOfficialJoin.isEntranceWorthy(
            content: name,
            membership: userRef.membership,
            chatRole: userRef.chatRole,
          )) {
            final banner = VoiceStaffChatStyle.formatTierEntranceLine(
              displayName: name,
              user: userRef,
              section: 'canlı yayına',
            );
            if (banner.isNotEmpty) {
              ref.read(staffEntranceMarqueeProvider.notifier).enqueue(banner);
            }
          }
          final msgId =
              'join-$joinId-${DateTime.now().millisecondsSinceEpoch}';
          if (_seenIds.add(msgId)) {
            next = next.copyWith(
              lastJoinedDisplayName: name,
              messages: [
                ...next.messages,
                LiveRoomChatMessage(
                  id: msgId,
                  userId: joinId,
                  user: 'Sistem',
                  text: '$name yayına katıldı',
                  isSystem: true,
                ),
              ],
            );
          } else {
            next = next.copyWith(lastJoinedDisplayName: name);
          }
        }
        state = next;
      },
      onUserLeft: (userId) {
        LiveEventLog.viewerLeft(streamId: streamId, userId: userId);
      },
      onModeratorUpdated: (userId, isModerator) {
        _applyModeratorFlag(userId: userId, isModerator: isModerator);
      },
      onFortuneRequest: (_) {
        // Canlı yayın fal kuyruğu — ayrı provider ile yönetilir.
      },
      onStreamFortuneRequest: (map) {
        ref
            .read(liveFortuneRequestsProvider(streamId).notifier)
            .pushFromSse(map);
        final merged = ref
            .read(liveFortuneRequestsProvider(streamId).notifier)
            .state
            .requests
            .where((r) {
              final id = map['request'] is Map
                  ? (map['request'] as Map)['id']?.toString()
                  : map['id']?.toString();
              return id != null && r.id == id;
            })
            .firstOrNull;
        final userId = ref.read(authControllerProvider).valueOrNull?.id;
        if (userId == null || merged == null || merged.userId != userId) return;
        final notice = switch (merged.status) {
          LiveFortuneRequestStatus.reviewing =>
            'Fal isteğiniz kabul edildi — yayıncı falınıza başlıyor.',
          LiveFortuneRequestStatus.held =>
            'Fal isteğiniz bekletildi — sıra size gelince bilgilendirileceksiniz.',
          LiveFortuneRequestStatus.answered =>
            'Fal isteğiniz yanıtlandı. Canlı yayına katılarak falınızı dinleyebilirsiniz.',
          LiveFortuneRequestStatus.cancelled =>
            'Yayıncı fal isteğinizi reddetti — jetonlarınız iade edildi.',
          LiveFortuneRequestStatus.pending => null,
        };
        if (notice != null) {
          state = state.copyWith(fortuneAnsweredNotice: notice);
        }
      },
    );

    _startLiveNamespaceSocket(streamId);
  }

  void _startLiveNamespaceSocket(String streamId) {
    final storage = ref.read(tokenStorageProvider);
    _liveSocket = ref.read(liveNamespaceSocketProvider);
    final pkState = ref.read(liveVideoPkProvider(streamId));
    final battleId = pkState.unifiedMatchId ??
        pkState.battle?['id']?.toString() ??
        pkState.battle?['battleId']?.toString();

    _liveSocket!.connect(
      accessToken: storage.readAccess,
      streamId: streamId,
      battleId: battleId,
      onPkScoreUpdate: (payload) {
        final battle = payload['battle'] ?? payload['match'] ?? payload;
        if (battle is Map) {
          ref
              .read(liveVideoPkProvider(streamId).notifier)
              .applyRemoteBattle(Map<String, dynamic>.from(battle));
        }
      },
      onPkInvite: (payload) {
        ref.invalidate(pkPendingInvitesProvider);
        ref.invalidate(livePkStreamsProvider);
        ref.read(livePkInviteSignalProvider.notifier).bump();
        final battle = payload['battle'] ?? payload['match'] ?? payload;
        if (battle is Map) {
          ref
              .read(liveVideoPkProvider(streamId).notifier)
              .applyRemoteBattle(Map<String, dynamic>.from(battle));
        }
        LiveDebugLog.log('live.ns.pk_invite', payload);
      },
      onGuestJoined: (guest) async {
        LiveDebugLog.log('live.ns.guest_joined', guest);
        await ref.read(coBroadcastProvider.notifier).refreshStream(streamId);
        final co = ref.read(coBroadcastProvider).coBroadcasters;
        final layout = resolveGuestLayout(guestCount: co.length);
        ref.read(liveBroadcastSettingsProvider.notifier)
          ..toggleCoBroadcast(true)
          ..toggleGuests(true)
          ..setGuestLayout(layout);
        ref.read(liveGuestGridProvider.notifier)
          ..setLayout(layout)
          ..syncCoBroadcasters(co);
      },
      onGuestLeft: (_) async {
        await ref.read(coBroadcastProvider.notifier).refreshStream(streamId);
        final co = ref.read(coBroadcastProvider).coBroadcasters;
        ref.read(liveGuestGridProvider.notifier).syncCoBroadcasters(co);
      },
      onReconnect: () {
        ref.read(coBroadcastProvider.notifier).refreshStream(streamId);
        ref.read(liveVideoPkProvider(streamId).notifier).refresh();
      },
    );
  }

  void _mergeMessages(List<LiveStreamChatMessage> incoming) {
    if (incoming.isEmpty) return;
    final list = [...state.messages];
    for (final m in incoming) {
      if (m.id.isEmpty || !_seenIds.add(m.id)) continue;
      list.add(
        LiveRoomChatMessage(
          id: m.id,
          userId: m.userId,
          user: m.displayName,
          text: m.content,
          isSystem: m.isSystem,
          isVip: m.isVip,
          isModerator: m.isModerator,
          isFortuneTeller: m.isFortuneTeller,
          level: m.level,
          entranceTheme: m.entranceTheme,
        ),
      );
    }
    state = state.copyWith(messages: list);
  }

  void _applyModeratorFlag({
    required String userId,
    required bool isModerator,
  }) {
    if (userId.isEmpty) return;
    var changed = false;
    final list = state.messages.map((m) {
      if (m.userId != userId) return m;
      changed = true;
      return LiveRoomChatMessage(
        id: m.id,
        userId: m.userId,
        user: m.user,
        text: m.text,
        isSystem: m.isSystem,
        isVip: m.isVip,
        isModerator: isModerator,
        isFortuneTeller: m.isFortuneTeller,
        level: m.level,
        entranceTheme: m.entranceTheme,
      );
    }).toList();
    if (changed) state = state.copyWith(messages: list);
  }

  Future<void> sendMessage(String text, {required String selfName}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending || state.streamEnded) return;

    if (ref.read(liveStreamEngagementProvider.notifier).tryVoteFromChat(
          trimmed,
          selfName,
        )) {
      return;
    }

    final guardError = LiveChatGuard.validate(trimmed);
    if (guardError != null) {
      state = state.copyWith(error: guardError);
      return;
    }

    final optimisticId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      sending: true,
      messages: [
        ...state.messages,
        LiveRoomChatMessage(id: optimisticId, user: selfName, text: trimmed),
      ],
      clearError: true,
    );
    try {
      final sent = await ref.read(liveRemoteProvider).sendStreamMessage(
            streamId: arg,
            content: trimmed,
          );
      var list = [...state.messages]..removeWhere((m) => m.id == optimisticId);
      // SSE, gönderilen mesajı biz cevabı almadan geri yollamış olabilir; bu
      // durumda _seenIds zaten içeriyor olur — ikinci kez eklemeyelim.
      if (sent != null && _seenIds.add(sent.id)) {
        list.add(
          LiveRoomChatMessage(
            id: sent.id,
            user: sent.displayName,
            text: LiveChatGuard.sanitizeForDisplay(sent.content),
          ),
        );
      }
      LiveChatGuard.markSent(trimmed);
      state = state.copyWith(messages: list, sending: false);
    } catch (e) {
      state = state.copyWith(
        sending: false,
        messages: state.messages.where((m) => m.id != optimisticId).toList(),
        error: ApiException.userMessage(e),
      );
    }
  }

  void setViewerCount(int count) {
    if (count >= 0) state = state.copyWith(viewerCount: count);
  }

  void markStreamEnded() {
    state = state.copyWith(streamEnded: true);
  }

  void clearFortuneAnsweredNotice() {
    if (state.fortuneAnsweredNotice != null) {
      state = state.copyWith(clearFortuneNotice: true);
    }
  }

  /// Hediye olayı — sohbet alanına sistem mesajı.
  void appendGiftSystemMessage(LiveGiftEvent ev) {
    if (ev.jetonAmount <= 0) return;
    final msgId = 'gift-${ev.id}';
    if (!_seenIds.add(msgId)) return;
    state = state.copyWith(
      messages: [
        ...state.messages,
        LiveRoomChatMessage(
          id: msgId,
          user: 'Sistem',
          text: GiftSystemMessage.format(ev),
          isSystem: true,
        ),
      ],
    );
  }

  void appendSessionSummaryMessages(
    SessionGiftSummary summary, {
    int? viewerCount,
    Duration? duration,
    String endedLabel = 'Yayın sona erdi',
  }) {
    final lines = SessionSummaryMessage.lines(
      summary,
      viewerCount: viewerCount,
      duration: duration,
      endedLabel: endedLabel,
    );
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final msgId =
          'summary-${trimmed.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
      if (!_seenIds.add(msgId)) continue;
      state = state.copyWith(
        messages: [
          ...state.messages,
          LiveRoomChatMessage(
            id: msgId,
            user: 'Sistem',
            text: trimmed,
            isSystem: true,
          ),
        ],
      );
    }
  }
}

final liveRoomProvider =
    AutoDisposeNotifierProviderFamily<LiveRoomController, LiveRoomState, String>(
  LiveRoomController.new,
);
