import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../widgets/broadcast_room/live_room_chat_message.dart';
import 'live_providers.dart';
import '../gifts/providers/live_gift_providers.dart';

class LiveRoomState {
  const LiveRoomState({
    this.messages = const [],
    this.viewerCount = 0,
    this.streamEnded = false,
    this.sending = false,
    this.error,
  });

  final List<LiveRoomChatMessage> messages;
  final int viewerCount;
  final bool streamEnded;
  final bool sending;
  final String? error;

  LiveRoomState copyWith({
    List<LiveRoomChatMessage>? messages,
    int? viewerCount,
    bool? streamEnded,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return LiveRoomState(
      messages: messages ?? this.messages,
      viewerCount: viewerCount ?? this.viewerCount,
      streamEnded: streamEnded ?? this.streamEnded,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
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
      ref.read(liveGiftSocketBridgeProvider).disconnect();
      unawaited(ref.read(liveRemoteProvider).leaveVideoStream(streamId));
    });
    Future.microtask(() => _bootstrap(streamId));
    return const LiveRoomState();
  }

  Future<void> _bootstrap(String streamId) async {
    try {
      final remote = ref.read(liveRemoteProvider);
      final count = await remote.joinVideoStream(streamId);
      state = state.copyWith(viewerCount: count, clearError: true);
      final history = await remote.fetchStreamMessages(streamId);
      _mergeMessages(history);
      _startRealtime(streamId);
      _poll = Timer.periodic(const Duration(seconds: 8), (_) async {
        if (state.streamEnded) return;
        try {
          final latest = await remote.fetchStreamMessages(streamId);
          _mergeMessages(latest);
          final meta = await remote.fetchStream(streamId);
          if (meta != null && !meta.isLive) {
            state = state.copyWith(streamEnded: true);
          }
        } catch (_) {}
      });
    } catch (e) {
      state = state.copyWith(error: ApiException.userMessage(e));
    }
  }

  void _startRealtime(String streamId) {
    ref.read(liveGiftSocketBridgeProvider).connect(
      streamId: streamId,
      onEvent: (ev) {
        ref.read(liveGiftRealtimeProvider).publishRemote(ev);
      },
      onChat: (msg) => _mergeMessages([msg]),
      onViewerCount: (count) {
        if (count >= 0) state = state.copyWith(viewerCount: count);
      },
      onStreamEnded: () {
        state = state.copyWith(streamEnded: true);
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
          user: m.displayName,
          text: m.content,
          isSystem: m.isSystem,
        ),
      );
    }
    final merged = list;
    state = state.copyWith(messages: merged);
  }

  Future<void> sendMessage(String text, {required String selfName}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending || state.streamEnded) return;
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
      if (sent != null) {
        _seenIds.add(sent.id);
        list.add(
          LiveRoomChatMessage(
            id: sent.id,
            user: sent.displayName,
            text: sent.content,
          ),
        );
      }
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
}

final liveRoomProvider =
    AutoDisposeNotifierProviderFamily<LiveRoomController, LiveRoomState, String>(
  LiveRoomController.new,
);
