import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../trtc/data/datasources/live_room_remote_datasource.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../providers/chat_room_providers.dart';
import 'voice_room_leave_trace.dart';
import 'voice_room_lifecycle_trace.dart';
import 'voice_room_server_leave_dedupe.dart';

/// Sunucuda tek bir sesli oda için tam çıkış: koltuk, live üyelik, presence (`leave=1`).
Future<bool> leaveVoiceRoomOnServer(
  Ref ref, {
  required String roomKey,
  String? alternateKey,
  String? userId,
}) =>
    leaveVoiceRoomOnServerWithClients(
      chatRemote: ref.read(chatRoomRemoteProvider),
      liveRemote: ref.read(liveRoomRemoteProvider),
      roomKey: roomKey,
      alternateKey: alternateKey,
      userId: userId,
    );

Future<bool> leaveVoiceRoomOnServerWithClients({
  required ChatRoomRemoteDataSource chatRemote,
  required LiveRoomRemoteDataSource liveRemote,
  required String roomKey,
  String? alternateKey,
  String? userId,
  bool trace = true,
}) async {
  final key = roomKey.trim();
  if (key.isEmpty) return false;
  final uid = userId?.trim();

  return VoiceRoomServerLeaveDedupe.run(
    roomKey: key,
    userId: uid,
    operation: () => _leaveVoiceRoomOnServerOnce(
      chatRemote: chatRemote,
      liveRemote: liveRemote,
      roomKey: key,
      alternateKey: alternateKey,
      userId: uid,
      trace: trace,
    ),
  );
}

Future<bool> _leaveVoiceRoomOnServerOnce({
  required ChatRoomRemoteDataSource chatRemote,
  required LiveRoomRemoteDataSource liveRemote,
  required String roomKey,
  String? alternateKey,
  String? userId,
  required bool trace,
}) async {
  if (trace) {
    VoiceRoomLifecycleTrace.lifecycle(
      roomId: roomKey,
      generation: -1,
      active: false,
      step: 'LEAVE_PRESENCE',
    );
    VoiceRoomLeaveTrace.log('presence leave started', {
      'roomId': roomKey,
      'alternateKey': alternateKey ?? '',
    });
  }
  var presenceAccepted = false;
  try {
    presenceAccepted =
        await chatRemote.leavePresence(roomKey, alternateKey: alternateKey);
    if (trace) {
      VoiceRoomLeaveTrace.log('presence leave response', {
        'accepted': presenceAccepted,
      });
    }
  } on ApiException catch (e) {
    if (trace) {
      VoiceRoomLeaveTrace.log('presence leave response', {
        'accepted': false,
        'httpStatus': e.statusCode ?? 0,
        'body': e.message,
      });
    }
  } catch (e) {
    if (trace) {
      VoiceRoomLeaveTrace.log('presence leave response', {
        'accepted': false,
        'error': e.toString(),
      });
    }
  }

  if (userId != null && userId.isNotEmpty && !presenceAccepted) {
    if (trace) {
      VoiceRoomLifecycleTrace.lifecycle(
        roomId: roomKey,
        generation: -1,
        active: false,
        step: 'LEAVE_SEAT',
      );
      VoiceRoomLeaveTrace.log('seat leave started', {
        'roomId': roomKey,
        'userId': userId,
        'alternateKey': alternateKey ?? '',
        'reason': 'presence_not_accepted',
      });
    }
    try {
      await chatRemote.clearSeat(
        roomKey: roomKey,
        alternateKey: alternateKey,
        userId: userId,
      );
      if (trace) VoiceRoomLeaveTrace.log('seat leave response', {'ok': true});
    } on ApiException catch (e) {
      if (trace) {
        VoiceRoomLeaveTrace.log('seat leave response', {
          'ok': e.statusCode == 409,
          'httpStatus': e.statusCode ?? 0,
          'body': e.message,
          'note': e.statusCode == 409 ? 'already_clear_conflict' : null,
        });
        VoiceRoomLifecycleTrace.seatRequest(
          action: 'clearSeat',
          roomId: roomKey,
          userId: userId,
          httpStatus: e.statusCode,
          detail: e.message,
          duplicate: e.statusCode == 409,
        );
      }
    } catch (e) {
      if (trace) {
        VoiceRoomLeaveTrace.log('seat leave response', {
          'ok': false,
          'error': e.toString(),
        });
      }
    }
  }

  if (trace) {
    VoiceRoomLeaveTrace.log('live leave-room started', {'roomId': roomKey});
  }
  try {
    await liveRemote
        .leaveRoom(roomId: roomKey, roomType: 'voice')
        .timeout(const Duration(seconds: 4));
    if (trace) VoiceRoomLeaveTrace.log('live leave-room response', {'ok': true});
  } on ApiException catch (e) {
    if (trace) {
      VoiceRoomLeaveTrace.log('live leave-room response', {
        'ok': false,
        'httpStatus': e.statusCode ?? 0,
        'body': e.message,
      });
    }
  } catch (e) {
    if (trace) {
      VoiceRoomLeaveTrace.log('live leave-room response', {
        'ok': false,
        'error': e.toString(),
      });
    }
  }

  return presenceAccepted;
}
