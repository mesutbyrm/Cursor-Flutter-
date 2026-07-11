import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/performance/network_perf.dart';
import '../../../../core/network/sse/sse_hub_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../domain/entities/live_fortune_request_entity.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/utils/live_chat_guard.dart';
import '../widgets/broadcast_room/live_room_chat_message.dart';
import 'live_providers.dart';
import 'live_stream_engagement_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../gifts/providers/live_gift_providers.dart';
import 'live_fortune_request_provider.dart';
import 'live_gift_leaderboard_provider.dart';
import 'live_room_interaction_provider.dart';
import 'live_video_pk_provider.dart';

class LiveRoomState {
  const LiveRoomState({
    this.messages = const [],
    this.viewerCount = 0,
    this.streamEnded = false,
    this.sending = false,
    this.sseConnected = false,
    this.error,
    this.fortuneAnsweredNotice,
  });

  final List<LiveRoomChatMessage> messages;
  final int viewerCount;
  final bool streamEnded;
  final bool sending;
  final bool sseConnected;
  final String? error;
  final String? fortuneAnsweredNotice;

  LiveRoomState copyWith({
    List<LiveRoomChatMessage>? messages,
    int? viewerCount,
    bool? streamEnded,
    bool? sending,
    bool? sseConnected,
    String? error,
    String? fortuneAnsweredNotice,
    bool clearError = false,
    bool clearFortuneNotice = false,
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
    );
  }
}

class LiveRoomController extends AutoDisposeFamilyNotifier<LiveRoomState, String> {
  Timer? _poll;
  final Set<String> _seenIds = {};

  @override
  LiveRoomState build(String streamId) {
    ref.onDispose(() {
      _poll?.cancel();
      ref.read(sseConnectionHubProvider).releaseVideoStream(streamId);
      unawaited(ref.read(liveRemoteProvider).leaveVideoStream(streamId));
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
        LiveDebugLog.log('stream.room.sse_ok', {'streamId': streamId});
      },
      onViewerCount: (count) {
        if (count >= 0) state = state.copyWith(viewerCount: count);
      },
      onMessage: (msg) => _mergeMessages([msg]),
      onGift: (ev) {
        ref.read(liveGiftRealtimeProvider).publishRemote(ev);
        ref.read(liveGiftLeaderboardProvider(streamId).notifier).record(ev);
      },
      onStreamEnded: () => state = state.copyWith(streamEnded: true),
      onPkBattle: (battle) {
        ref.read(liveVideoPkProvider(streamId).notifier).applyRemoteBattle(battle);
      },
      onLike: (count) {
        ref
            .read(liveRoomInteractionProvider(streamId).notifier)
            .syncRemoteLikeCount(count);
      },
      onUserJoined: (user) {
        final count = user['viewerCount'] ?? user['viewers'] ?? user['watching'];
        if (count is num) {
          state = state.copyWith(viewerCount: count.round());
        }
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

  void clearFortuneAnsweredNotice() {
    if (state.fortuneAnsweredNotice != null) {
      state = state.copyWith(clearFortuneNotice: true);
    }
  }
}

final liveRoomProvider =
    AutoDisposeNotifierProviderFamily<LiveRoomController, LiveRoomState, String>(
  LiveRoomController.new,
);
