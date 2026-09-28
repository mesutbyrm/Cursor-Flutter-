import '../entities/co_broadcast_entity.dart';

abstract class CoBroadcastRepository {
  Future<CoBroadcast> getCoBroadcast(String broadcastId);
  Future<void> inviteGuest(String broadcastId, String guestId);
  Future<void> acceptInvite(String requestId);
  Future<void> declineInvite(String requestId);
  Future<List<CoBroadcastRequest>> getPendingRequests(String userId);
  Future<void> setAudioMix(String broadcastId, bool enabled);
  Future<void> setGuestPermission(String broadcastId, String permission, bool enabled);
  Future<void> endCoBroadcast(String broadcastId);
}
