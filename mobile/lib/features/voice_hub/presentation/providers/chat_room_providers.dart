import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';

final chatRoomRemoteProvider = Provider<ChatRoomRemoteDataSource>((ref) {
  return ChatRoomRemoteDataSource(ref.watch(dioProvider));
});

class VoiceRoomLiveState {
  const VoiceRoomLiveState({
    this.messages = const [],
    this.presence = const [],
    this.dj = const ChatRoomDjState(),
    this.loading = true,
    this.error,
    this.sending = false,
  });

  final List<ChatRoomMessage> messages;
  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final bool loading;
  final String? error;
  final bool sending;

  int get onlineCount =>
      presence.isNotEmpty ? presence.length : 0;

  VoiceRoomLiveState copyWith({
    List<ChatRoomMessage>? messages,
    List<ChatRoomPresence>? presence,
    ChatRoomDjState? dj,
    bool? loading,
    String? error,
    bool? sending,
  }) {
    return VoiceRoomLiveState(
      messages: messages ?? this.messages,
      presence: presence ?? this.presence,
      dj: dj ?? this.dj,
      loading: loading ?? this.loading,
      error: error,
      sending: sending ?? this.sending,
    );
  }
}

class VoiceRoomLiveController extends AutoDisposeFamilyNotifier<
    VoiceRoomLiveState, VoiceRoomEntity> {
  Timer? _poll;

  @override
  VoiceRoomLiveState build(VoiceRoomEntity room) {
    ref.onDispose(() {
      _poll?.cancel();
    });
    Future.microtask(refresh);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
    return const VoiceRoomLiveState();
  }

  Future<void> refresh() async {
    final room = arg;
    final remote = ref.read(chatRoomRemoteProvider);
    try {
      final results = await Future.wait([
        remote.fetchMessages(room.id),
        remote.fetchPresence(room.id),
        remote.fetchDj(room.id),
      ]);
      state = state.copyWith(
        messages: results[0] as List<ChatRoomMessage>,
        presence: results[1] as List<ChatRoomPresence>,
        dj: results[2] as ChatRoomDjState,
        loading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    state = state.copyWith(sending: true);
    try {
      await ref.read(chatRoomRemoteProvider).sendMessage(
            roomId: arg.id,
            content: trimmed,
          );
      await refresh();
    } finally {
      state = state.copyWith(sending: false);
    }
  }
}

final voiceRoomLiveProvider = NotifierProvider.autoDispose
    .family<VoiceRoomLiveController, VoiceRoomLiveState, VoiceRoomEntity>(
  VoiceRoomLiveController.new,
);
