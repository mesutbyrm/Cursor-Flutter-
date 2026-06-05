import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import 'voice_room_socket_helper.dart';

/// Sesli oda hediye socket — `joinRoom` + `gift` olayları.
class VoiceRoomGiftSocket {
  VoiceRoomGiftSocket(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  io.Socket? _socket;
  void Function(LiveGiftEvent)? _onEvent;
  void Function(Map<String, dynamic> payload)? _onDjUpdate;
  List<String> _joinKeys = const [];

  void connect({
    required String roomId,
    String? alternateRoomId,
    required void Function(LiveGiftEvent event) onEvent,
    void Function(Map<String, dynamic> payload)? onDjUpdate,
    Future<String?> Function()? accessToken,
  }) {
    _onEvent = onEvent;
    _onDjUpdate = onDjUpdate;
    _joinKeys = VoiceRoomSocketHelper.joinKeys(
      primary: roomId,
      alternate: alternateRoomId,
    );
    Future.microtask(() async {
      try {
        final token = accessToken != null ? await accessToken() : null;
        _socket?.dispose();
        _socket = io.io(
          Env.siteOrigin,
          VoiceRoomSocketHelper.baseOptions(bearerToken: token).build(),
        );
        _socket!
          ..onConnect((_) => VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys))
          ..onReconnect((_) =>
              VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys))
          ..on('gift', (data) => _emit(data, roomId))
          ..on('giftSent', (data) => _emit(data, roomId))
          ..on('dj', (data) => _emitDj(data))
          ..on('music', (data) => _emitDj(data))
          ..on('QUEUE_UPDATED', (data) => _emitDj(data))
          ..on('CURRENT_SONG_CHANGED', (data) => _emitDj(data))
          ..connect();
      } catch (e) {
        debugPrint('Voice gift socket: $e');
      }
    });
  }

  void _emit(dynamic data, String roomId) {
    if (data is! Map) return;
    final ev = _remote.parseGiftEvent(
      Map<String, dynamic>.from(data),
      streamId: roomId,
    );
    if (ev != null) _onEvent?.call(ev);
  }

  void _emitDj(dynamic data) {
    if (data is! Map) return;
    _onDjUpdate?.call(Map<String, dynamic>.from(data));
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _onEvent = null;
    _onDjUpdate = null;
    _joinKeys = const [];
  }
}
