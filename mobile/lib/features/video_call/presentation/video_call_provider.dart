import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/domain/entities/live_fortune_session_entity.dart';
import '../../home/presentation/providers/fortune_incoming_invite_provider.dart';
import '../../home/presentation/providers/fortune_live_event_bus.dart';
import '../data/video_call_invitation_service.dart';
import '../domain/video_call_invitation.dart';

final videoCallInvitationServiceProvider =
    Provider<VideoCallInvitationService>((ref) {
  final service = VideoCallInvitationService();
  ref.onDispose(service.dispose);
  return service;
});

class VideoCallState {
  const VideoCallState({
    this.active,
    this.queue = const [],
    this.presenting = false,
    this.lastMissedCallId,
  });

  final VideoCallInvitation? active;
  final List<VideoCallInvitation> queue;
  final bool presenting;
  final String? lastMissedCallId;

  bool get hasIncoming => active != null || queue.isNotEmpty;

  VideoCallState copyWith({
    VideoCallInvitation? active,
    bool clearActive = false,
    List<VideoCallInvitation>? queue,
    bool? presenting,
    String? lastMissedCallId,
    bool clearMissed = false,
  }) {
    return VideoCallState(
      active: clearActive ? null : (active ?? this.active),
      queue: queue ?? this.queue,
      presenting: presenting ?? this.presenting,
      lastMissedCallId:
          clearMissed ? null : (lastMissedCallId ?? this.lastMissedCallId),
    );
  }
}

class VideoCallNotifier extends Notifier<VideoCallState> {
  StreamSubscription<VideoCallInvitation>? _sub;
  StreamSubscription<FortuneIncomingSession>? _fortuneSub;

  @override
  VideoCallState build() {
    final service = ref.watch(videoCallInvitationServiceProvider);
    _sub?.cancel();
    _sub = service.incoming.listen(_onIncoming, onError: _onTimeout);
    _fortuneSub?.cancel();
    _fortuneSub = ref.watch(fortuneLiveEventBusProvider).stream.listen(
      (session) => service.handleFortuneSession(session),
    );
    ref.onDispose(() {
      _sub?.cancel();
      _fortuneSub?.cancel();
    });
    return const VideoCallState();
  }

  void _onIncoming(VideoCallInvitation invite) {
    if (state.active?.callId == invite.callId) return;
    if (state.active == null) {
      state = state.copyWith(active: invite);
      return;
    }
    final q = [...state.queue];
    if (!q.any((e) => e.callId == invite.callId)) q.add(invite);
    state = state.copyWith(queue: q);
  }

  void _onTimeout(Object error) {
    if (error is VideoCallTimeoutException) {
      _dismissActive(error.callId, missed: true);
    }
  }

  void setPresenting(bool value) {
    state = state.copyWith(presenting: value);
  }

  void respond(String callId, VideoCallResponse response) {
    ref.read(videoCallInvitationServiceProvider).cancel(callId, reason: response);
    _dismissActive(callId, missed: response == VideoCallResponse.missed ||
        response == VideoCallResponse.timeout);
  }

  void _dismissActive(String callId, {bool missed = false}) {
    if (state.active?.callId != callId) return;
    final next = state.queue.isNotEmpty ? state.queue.first : null;
    final rest = state.queue.length > 1
        ? state.queue.sublist(1)
        : <VideoCallInvitation>[];
    state = state.copyWith(
      clearActive: next == null,
      active: next,
      queue: rest,
      presenting: false,
      lastMissedCallId: missed ? callId : state.lastMissedCallId,
    );
  }

  /// Fortune kuyruğu ile senkron — mevcut davet sistemi korunur.
  void syncFromFortuneQueue(List<FortuneIncomingSession> sessions) {
    for (final s in sessions) {
      ref.read(videoCallInvitationServiceProvider).handleFortuneSession(s);
    }
  }
}

final videoCallProvider =
    NotifierProvider<VideoCallNotifier, VideoCallState>(VideoCallNotifier.new);

/// Fortune invite provider ile köprü.
final videoCallFortuneBridgeProvider = Provider<void>((ref) {
  ref.listen(fortuneIncomingInviteProvider, (prev, next) {
    if (next.isEmpty) return;
    ref.read(videoCallProvider.notifier).syncFromFortuneQueue(next);
  });
});
