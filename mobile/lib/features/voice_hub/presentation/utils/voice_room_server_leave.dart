import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../trtc/data/datasources/live_room_remote_datasource.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../providers/chat_room_providers.dart';
import 'voice_room_leave_trace.dart';

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
  if (uid != null && uid.isNotEmpty) {
    if (trace) {
      VoiceRoomLeaveTrace.log('seat leave started', {
        'roomId': key,
        'userId': uid,
        'alternateKey': alternateKey ?? '',
      });
    }
    try {
      await chatRemote.clearSeat(
        roomKey: key,
        alternateKey: alternateKey,
        userId: uid,
      );
      if (trace) VoiceRoomLeaveTrace.log('seat leave response', {'ok': true});
    } on ApiException catch (e) {
      if (trace) {
        VoiceRoomLeaveTrace.log('seat leave response', {
          'ok': false,
          'httpStatus': e.statusCode ?? 0,
          'body': e.message,
        });
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
    VoiceRoomLeaveTrace.log('live leave-room started', {'roomId': key});
  }
  try {
    await liveRemote
        .leaveRoom(roomId: key, roomType: 'voice')
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
  if (trace) {
    VoiceRoomLeaveTrace.log('presence leave started', {
      'roomId': key,
      'alternateKey': alternateKey ?? '',
    });
  }
  try {
    final accepted =
        await chatRemote.leavePresence(key, alternateKey: alternateKey);
    if (trace) {
      VoiceRoomLeaveTrace.log('presence leave response', {
        'accepted': accepted,
      });
    }
    return accepted;
  } on ApiException catch (e) {
    if (trace) {
      VoiceRoomLeaveTrace.log('presence leave response', {
        'accepted': false,
        'httpStatus': e.statusCode ?? 0,
        'body': e.message,
      });
    }
    return false;
  } catch (e) {
    if (trace) {
      VoiceRoomLeaveTrace.log('presence leave response', {
        'accepted': false,
        'error': e.toString(),
      });
    }
    return false;
  }
}
