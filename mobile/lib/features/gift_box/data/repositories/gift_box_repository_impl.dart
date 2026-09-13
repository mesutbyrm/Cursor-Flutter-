import '../../domain/repositories/gift_box_repository.dart';
import '../datasources/gift_box_remote_datasource.dart';

class GiftBoxRepositoryImpl implements GiftBoxRepository {
  GiftBoxRepositoryImpl(this._remote);

  final GiftBoxRemoteDataSource _remote;

  @override
  Future<Map<String, dynamic>> listActive({
    String? roomId,
    String? streamId,
  }) =>
      _remote.listActive(roomId: roomId, streamId: streamId);

  @override
  Future<Map<String, dynamic>> getBox(String boxId) => _remote.getBox(boxId);

  @override
  Future<Map<String, dynamic>> postAction(
    Map<String, dynamic> body, {
    String? roomId,
    String? streamId,
  }) =>
      _remote.postAction(body, roomId: roomId, streamId: streamId);

  @override
  Future<Map<String, dynamic>> joinBox(String boxId) => _remote.joinBox(boxId);

  @override
  Future<Map<String, dynamic>> recordShare(Map<String, dynamic> body) =>
      _remote.recordShare(body);

  @override
  Future<Map<String, dynamic>> fetchRoomSync(String roomId) =>
      _remote.fetchRoomSync(roomId);

  @override
  Future<Map<String, dynamic>> fetchStreamSync(String streamId) =>
      _remote.fetchStreamSync(streamId);
}
