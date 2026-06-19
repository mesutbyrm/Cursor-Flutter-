import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import '../../live_psychics/domain/entities/psychic_request_entity.dart';
import '../../live_psychics/presentation/providers/psychic_live_event_bus.dart';
import '../../live_psychics/presentation/providers/psychic_push_payload.dart';
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
  StreamSubscription<PsychicRequestEntity>? _psychicSub;

  @override
  VideoCallState build() {
    final service = ref.watch(videoCallInvitationServiceProvider);
    _sub?.cancel();
    _sub = service.incoming.listen(_onIncoming, onError: _onTimeout);
    _psychicSub?.cancel();
    _psychicSub = ref.watch(psychicLiveEventBusProvider).stream.listen(
      (request) => service.handlePsychicRequest(request),
    );
    ref.onDispose(() {
      _sub?.cancel();
      _psychicSub?.cancel();
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

  void syncFromPsychicQueue(List<PsychicRequestEntity> requests) {
    for (final r in requests) {
      ref.read(videoCallInvitationServiceProvider).handlePsychicRequest(r);
    }
  }
}

final videoCallProvider =
    NotifierProvider<VideoCallNotifier, VideoCallState>(VideoCallNotifier.new);

/// Psychic invite kuyruğu ile köprü.
final videoCallPsychicBridgeProvider = Provider<void>((ref) {
  ref.listen(psychicIncomingQueueProvider, (prev, next) {
    if (next.isEmpty) return;
    ref.read(videoCallProvider.notifier).syncFromPsychicQueue(next);
  });
});
