import '../../../../core/network/live_debug_log.dart';

/// Socket.IO `/live` namespace — **devre dışı**.
///
/// Backend contract SSE only. Bu sınıf public API'yi korur ama bağlanmaz.
/// PK / misafir / hediye olayları video stream SSE üzerinden gelir.
class LiveNamespaceSocketService {
  bool get connected => false;

  void connect({
    required Future<String?> Function() accessToken,
    String? streamId,
    List<String>? streamIds,
    String? battleId,
    void Function(Map<String, dynamic> payload)? onPkScoreUpdate,
    void Function(Map<String, dynamic> payload)? onPkInvite,
    void Function(Map<String, dynamic> guest)? onGuestJoined,
    void Function(Map<String, dynamic> payload)? onGuestLeft,
    void Function(Map<String, dynamic> payload)? onGift,
    void Function()? onReconnect,
    void Function(bool connected)? onConnectionChanged,
  }) {
    LiveDebugLog.log('live.ns.disabled', {
      'reason': 'sse_only',
      'streamId': streamId,
      'battleId': battleId,
    });
  }

  void updateRooms({
    String? streamId,
    List<String>? streamIds,
    String? battleId,
  }) {}

  void disconnect() {}
}
