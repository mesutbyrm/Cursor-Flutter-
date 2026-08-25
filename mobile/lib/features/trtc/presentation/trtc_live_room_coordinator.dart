import 'dart:async';

import '../../../core/network/api_exception.dart';
import '../../../core/network/live_debug_log.dart';
import '../../../core/network/live_event_log.dart';
import '../data/datasources/live_room_remote_datasource.dart';
import '../data/datasources/trtc_remote_datasource.dart';
import '../data/trtc_session_store.dart';
import '../domain/entities/live_join_room_result.dart';
import '../domain/entities/trtc_credentials.dart';
import '../domain/trtc_reconnect_gate.dart';
import 'trtc_room_manager.dart';

typedef TrtcJoinRoomFn = Future<void> Function({
  required TrtcCredentials credentials,
  required bool isHost,
  required bool audioOnly,
  String? expectedAnchorUserId,
  bool twoWayVideo,
});

/// Canlı oda TRTC oturumu — join-room, 10 sn heartbeat, yeniden bağlanma.
class TrtcLiveRoomCoordinator {
  TrtcLiveRoomCoordinator({
    required LiveRoomRemoteDataSource liveRoom,
    required TrtcRemoteDataSource trtcRemote,
    required TrtcRoomManager roomManager,
    TrtcJoinRoomFn? joinRoomFn,
  })  : _liveRoom = liveRoom,
        _trtcRemote = trtcRemote,
        _roomManager = roomManager,
        _joinRoomFn = joinRoomFn ?? roomManager.join;

  final LiveRoomRemoteDataSource _liveRoom;
  final TrtcRemoteDataSource _trtcRemote;
  final TrtcRoomManager _roomManager;
  final TrtcJoinRoomFn _joinRoomFn;

  static const heartbeatInterval = Duration(seconds: 10);

  Timer? _heartbeat;
  Timer? _hardReconnectTimer;
  var _disposed = false;
  var _reconnecting = false;
  var _reconnectSuspended = false;
  var _micOnBeforeReconnect = true;
  final _gate = TrtcReconnectGate();

  /// Dış join/rejoin sırasında heartbeat yeniden bağlanmasını durdur.
  void setReconnectSuspended(bool suspended) {
    _reconnectSuspended = suspended;
  }

  String? _roomId;
  String? _roomType;
  String? _userId;
  String _rtcRole = 'audience';
  bool _isHost = false;
  bool _twoWayVideo = false;
  bool _audioOnly = false;
  String? _expectedAnchorUserId;

  LiveJoinRoomResult? joinSnapshot;
  final _connectionLostController = StreamController<void>.broadcast();
  Stream<void> get onConnectionLost => _connectionLostController.stream;
  void Function()? onReconnected;

  TrtcRoomManager get roomManager => _roomManager;
  bool get isReconnecting => _reconnecting;

  Future<LiveJoinRoomResult> join({
    required String roomId,
    required String roomType,
    required String userId,
    required bool isHost,
    bool twoWayVideo = false,
    bool audioOnly = false,
    String? expectedAnchorUserId,
    String? nickname,
    bool useCompoundJoin = true,
  }) async {
    _disposed = false;
    _gate.onJoinStarted();
    _hardReconnectTimer?.cancel();
    _roomId = roomId.trim();
    _roomType = roomType;
    _userId = userId;
    _isHost = isHost;
    _twoWayVideo = twoWayVideo;
    _audioOnly = audioOnly;
    _expectedAnchorUserId = expectedAnchorUserId;
    _rtcRole = isHost ? 'host' : 'audience';

    LiveJoinRoomResult? compound;
    TrtcCredentials cred;

    if (useCompoundJoin) {
      try {
        compound = await _liveRoom.joinRoom(
          roomId: _roomId!,
          roomType: roomType,
          nickname: nickname,
        );
        cred = compound.trtc;
        joinSnapshot = compound;
      } catch (e) {
        LiveDebugLog.log('live.join_room.fallback', {
          'roomId': _roomId,
          'error': ApiException.userMessage(e),
        });
        cred = await _fetchCredentials(roomId: _roomId!, userId: userId);
      }
    } else {
      cred = await _fetchCredentials(roomId: _roomId!, userId: userId);
    }

    TrtcSessionStore.put(cred);
    _gate.onConnecting();
    await _enterTrtc(cred);
    LiveEventLog.trtcJoin(
      streamId: _roomId!,
      role: _rtcRole,
    );
    _gate.onConnected();
    _startHeartbeat();
    return compound ??
        LiveJoinRoomResult(
          room: LiveJoinRoomInfo(id: _roomId!),
          trtc: cred,
        );
  }

  Future<TrtcCredentials> _fetchCredentials({
    required String roomId,
    required String userId,
  }) async {
    return _trtcRemote.fetchToken(
      roomId: roomId,
      role: _rtcRole,
      userId: userId,
    );
  }

  Future<void> _enterTrtc(TrtcCredentials cred) async {
    _roomManager.onConnectionLost = _handleConnectionLost;
    _roomManager.onTryToReconnect = _handleSdkTryToReconnect;
    _roomManager.onConnectionRecovery = _handleSdkRecovery;
    await _joinRoomFn(
      credentials: cred,
      isHost: _isHost,
      audioOnly: _audioOnly,
      expectedAnchorUserId: _expectedAnchorUserId,
      twoWayVideo: _twoWayVideo,
    );
    _micOnBeforeReconnect = _roomManager.micOn;
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    final roomId = _roomId;
    final roomType = _roomType;
    if (roomId == null || roomType == null) return;

    _heartbeat = Timer.periodic(heartbeatInterval, (_) async {
      if (_disposed || !_roomManager.inRoom) return;
      try {
        await _liveRoom.heartbeat(roomId: roomId, roomType: roomType);
        LiveEventLog.heartbeat(streamId: roomId);
      } catch (e) {
        LiveDebugLog.log('live.heartbeat.fail', {
          'roomId': roomId,
          'error': ApiException.userMessage(e),
        });
        // Heartbeat REST hatası tek başına odayı kapatmaz; TRTC hâlâ bağlıysa bekle.
        if (!_roomManager.inRoom &&
            !_reconnecting &&
            !_reconnectSuspended &&
            _gate.shouldHardReconnect) {
          unawaited(reconnect());
        }
      }
    });
  }

  void _handleSdkTryToReconnect() {
    if (_disposed) return;
    _gate.onSdkTryToReconnect();
    LiveDebugLog.log('trtc.sdk.try_reconnect', {'roomId': _roomId});
  }

  void _handleSdkRecovery() {
    if (_disposed) return;
    _hardReconnectTimer?.cancel();
    _gate.onSdkRecovered();
    LiveDebugLog.log('trtc.sdk.recovered', {'roomId': _roomId});
    onReconnected?.call();
  }

  Future<void> _handleConnectionLost() async {
    if (_disposed || _reconnectSuspended) return;
    _gate.onSdkConnectionLost();
    _connectionLostController.add(null);
    if (_gate.shouldHardReconnect) {
      await reconnect();
      return;
    }
    _hardReconnectTimer?.cancel();
    final generation = _gate.generation;
    _hardReconnectTimer = Timer(_gate.sdkGrace, () {
      if (_disposed || _reconnectSuspended) return;
      if (generation != _gate.generation) return;
      if (_gate.phase == TrtcConnectionPhase.connected) return;
      if (_roomManager.inRoom &&
          _gate.phase != TrtcConnectionPhase.reconnecting) {
        return;
      }
      if (_gate.shouldHardReconnect) {
        unawaited(reconnect());
      }
    });
  }

  Future<void> reconnect() async {
    if (_disposed || _reconnecting || _reconnectSuspended) return;
    if (!_gate.shouldHardReconnect && _roomManager.inRoom) return;
    final roomId = _roomId;
    final userId = _userId;
    if (roomId == null || userId == null) return;

    _reconnecting = true;
    _gate.markHardReconnectStarted();
    _micOnBeforeReconnect = _roomManager.micOn;
    LiveDebugLog.log('trtc.reconnect.start', {'roomId': roomId});

    try {
      await _roomManager.leave();
      final cred = await _fetchCredentials(roomId: roomId, userId: userId);
      TrtcSessionStore.put(cred);
      await _enterTrtc(cred);
      _roomManager.setMicEnabled(_micOnBeforeReconnect);
      _gate.onHardReconnectFinished(success: true);
      LiveDebugLog.log('trtc.reconnect.ok', {'roomId': roomId});
      onReconnected?.call();
    } catch (e) {
      _gate.onHardReconnectFinished(success: false);
      LiveDebugLog.log('trtc.reconnect.fail', {
        'roomId': roomId,
        'error': ApiException.userMessage(e),
      });
      rethrow;
    } finally {
      _reconnecting = false;
    }
  }

  Future<void> leave() async {
    _hardReconnectTimer?.cancel();
    _gate.onClosed();
    _disposed = true;
    _heartbeat?.cancel();
    _heartbeat = null;
    _roomManager.onConnectionLost = null;
    _roomManager.onTryToReconnect = null;
    _roomManager.onConnectionRecovery = null;

    final roomId = _roomId;
    final roomType = _roomType;
    if (roomId != null) {
      LiveEventLog.leave(streamId: roomId, isHost: _isHost);
    }
    if (roomId != null && roomType != null) {
      try {
        await _liveRoom.leaveRoom(roomId: roomId, roomType: roomType);
      } catch (_) {}
    }

    try {
      await _roomManager.leave();
    } catch (_) {}

    TrtcSessionStore.clear();
    joinSnapshot = null;
    _roomId = null;
    _roomType = null;
  }

  void dispose() {
    _disposed = true;
    _hardReconnectTimer?.cancel();
    _heartbeat?.cancel();
    _connectionLostController.close();
    _roomManager.onConnectionLost = null;
    _roomManager.onTryToReconnect = null;
    _roomManager.onConnectionRecovery = null;
    unawaited(leave());
  }
}
