import '../../domain/entities/co_broadcast_entity.dart';
import '../../domain/repositories/co_broadcast_repository.dart';
import '../datasources/co_broadcast_datasource.dart';

class CoBroadcastRepositoryImpl implements CoBroadcastRepository {
  final CoBroadcastDataSource _dataSource;
  CoBroadcastRepositoryImpl({required CoBroadcastDataSource dataSource}) : _dataSource = dataSource;

  @override
  Future<CoBroadcast> getCoBroadcast(String broadcastId) async => (await _dataSource.getCoBroadcast(broadcastId)).toDomain();

  @override
  Future<void> inviteGuest(String broadcastId, String guestId) => _dataSource.inviteGuest(broadcastId, guestId);

  @override
  Future<void> acceptInvite(String requestId) => _dataSource.acceptInvite(requestId);

  @override
  Future<void> declineInvite(String requestId) => _dataSource.declineInvite(requestId);

  @override
  Future<List<CoBroadcastRequest>> getPendingRequests(String userId) async => (await _dataSource.getPendingRequests(userId)).map((dto) => dto.toDomain()).toList();

  @override
  Future<void> setAudioMix(String broadcastId, bool enabled) => _dataSource.setAudioMix(broadcastId, enabled);

  @override
  Future<void> setGuestPermission(String broadcastId, String permission, bool enabled) => _dataSource.setGuestPermission(broadcastId, permission, enabled);

  @override
  Future<void> endCoBroadcast(String broadcastId) => _dataSource.endCoBroadcast(broadcastId);
}
