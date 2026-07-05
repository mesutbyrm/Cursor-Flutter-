import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../video_call/data/video_call_invitation_service.dart';
import '../../../video_call/domain/video_call_invitation.dart';
import '../../../video_call/presentation/video_call_provider.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../providers/messages_providers.dart';

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

    final callId = 'dm-${DateTime.now().millisecondsSinceEpoch}';
    final channelId = channelFor(selfId, peerUserId);
    final signal = DmMessageCodec.callInvite(callId: callId, channelId: channelId);

    await _ref.read(messagesRepositoryProvider).sendCallSignal(peerUserId, signal);

    final invite = VideoCallInvitation(
      callId: callId,
      callerId: selfId,
      callerName: peerName,
      callerAvatarUrl: peerAvatarUrl,
      category: 'dm_voice',
      sessionId: channelId,
      receivedAt: DateTime.now(),
    );
    _ref.read(videoCallInvitationServiceProvider).enqueue(invite);
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
        if (peerUserId.isEmpty) return;
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
        // Arayan taraf kabulü işler — chat_page dinleyicisi açar.
        break;
      case DmCallRejectSignal():
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
}

final dmVoiceCallServiceProvider = Provider<DmVoiceCallService>((ref) {
  return DmVoiceCallService(ref);
});
