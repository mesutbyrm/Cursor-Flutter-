import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../video_call/data/video_call_invitation_service.dart';
import '../../../video_call/domain/video_call_invitation.dart';
import '../../../video_call/presentation/video_call_provider.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../providers/messages_providers.dart';

/// Bekleyen giden DM araması — kabul sinyali gelince sesli görüşme açılır.
class DmOutgoingCallState {
  const DmOutgoingCallState({
    required this.callId,
    required this.peerUserId,
    required this.peerName,
    required this.channelId,
  });

  final String callId;
  final String peerUserId;
  final String peerName;
  final String channelId;
}

final dmOutgoingCallProvider =
    StateProvider<DmOutgoingCallState?>((ref) => null);

/// Gold üyeler için DM sesli arama — mesaj sinyali + gelen arama UI.
class DmVoiceCallService {
  DmVoiceCallService(this._ref);

  final Ref _ref;

  static String channelFor(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm_${ids[0]}_${ids[1]}';
  }

  Future<void> startOutgoingCall({
    required String peerUserId,
    required String peerName,
    String? peerAvatarUrl,
  }) async {
    final selfId = _ref.read(authControllerProvider).valueOrNull?.id;
    if (selfId == null || peerUserId.isEmpty) return;
    if (peerUserId == selfId) return;

    final callId = 'dm-${DateTime.now().millisecondsSinceEpoch}';
    final channelId = channelFor(selfId, peerUserId);
    final signal = DmMessageCodec.callInvite(callId: callId, channelId: channelId);

    _ref.read(dmOutgoingCallProvider.notifier).state = DmOutgoingCallState(
      callId: callId,
      peerUserId: peerUserId,
      peerName: peerName,
      channelId: channelId,
    );

    await _ref.read(messagesRepositoryProvider).sendCallSignal(peerUserId, signal);
  }

  void handleRawMessage({
    required String peerUserId,
    required String peerName,
    String? peerAvatarUrl,
    required String rawContent,
  }) {
    final signal = DmMessageCodec.parseCallSignal(rawContent);
    if (signal == null) return;
    final selfId = _ref.read(authControllerProvider).valueOrNull?.id;
    if (selfId == null) return;

    switch (signal) {
      case DmCallInviteSignal():
        if (peerUserId.isEmpty || peerUserId == selfId) return;
        _ref.read(videoCallInvitationServiceProvider).enqueue(
              VideoCallInvitation(
                callId: signal.callId,
                callerId: peerUserId,
                callerName: peerName,
                callerAvatarUrl: peerAvatarUrl,
                category: 'dm_voice',
                sessionId: signal.channelId,
                receivedAt: DateTime.now(),
              ),
            );
      case DmCallAcceptSignal():
        final pending = _ref.read(dmOutgoingCallProvider);
        if (pending != null && pending.callId == signal.callId) {
          _ref.read(dmOutgoingCallAcceptedProvider.notifier).state =
              DmOutgoingCallState(
            callId: pending.callId,
            peerUserId: pending.peerUserId,
            peerName: pending.peerName,
            channelId: pending.channelId,
          );
          _ref.read(dmOutgoingCallProvider.notifier).state = null;
        }
      case DmCallRejectSignal():
        final pending = _ref.read(dmOutgoingCallProvider);
        if (pending != null && pending.callId == signal.callId) {
          _ref.read(dmOutgoingCallProvider.notifier).state = null;
        }
        _ref
            .read(videoCallProvider.notifier)
            .respond(signal.callId, VideoCallResponse.reject);
    }
  }

  Future<void> respondToCall({
    required VideoCallInvitation invite,
    required VideoCallResponse response,
    required String peerUserId,
  }) async {
    final signal = switch (response) {
      VideoCallResponse.accept => DmMessageCodec.callAccept(invite.callId),
      VideoCallResponse.reject ||
      VideoCallResponse.busy ||
      VideoCallResponse.timeout ||
      VideoCallResponse.missed =>
        DmMessageCodec.callReject(invite.callId),
    };
    if (peerUserId.isNotEmpty) {
      await _ref.read(messagesRepositoryProvider).sendCallSignal(peerUserId, signal);
    }
    _ref.read(videoCallProvider.notifier).respond(invite.callId, response);
  }

  void clearOutgoing() {
    _ref.read(dmOutgoingCallProvider.notifier).state = null;
  }
}

/// Arayan taraf kabul aldı — [DmVoiceCallHost] sesli görüşmeyi açar.
final dmOutgoingCallAcceptedProvider =
    StateProvider<DmOutgoingCallState?>((ref) => null);

final dmVoiceCallServiceProvider = Provider<DmVoiceCallService>((ref) {
  return DmVoiceCallService(ref);
});
