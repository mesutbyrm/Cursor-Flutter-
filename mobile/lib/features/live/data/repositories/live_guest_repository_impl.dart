import '../../../../core/network/api_exception.dart';
import '../../domain/live_guest_list_snapshot.dart';
import '../../domain/repositories/live_guest_repository.dart';
import '../datasources/live_api_remote_datasource.dart';
import '../datasources/live_stream_extras_datasource.dart';

class LiveGuestRepositoryImpl implements LiveGuestRepository {
  LiveGuestRepositoryImpl(this._liveApi, this._extras);

  final LiveApiRemoteDataSource _liveApi;
  final LiveStreamExtrasDataSource _extras;

  @override
  Future<LiveGuestListSnapshot> fetchGuestList({String? streamId}) =>
      _liveApi.fetchGuestList(streamId: streamId);

  @override
  Future<Map<String, dynamic>> fetchGuestSession({
    String? roomId,
    String? streamId,
    String? view,
  }) =>
      _liveApi.fetchGuestSession(
        roomId: roomId,
        streamId: streamId,
        view: view,
      );

  @override
  Future<Map<String, dynamic>> postGuestAction(
    Map<String, dynamic> body, {
    String? roomId,
    String? streamId,
    String? view,
  }) =>
      _liveApi.postGuestAction(
        body,
        roomId: roomId,
        streamId: streamId,
        view: view,
      );

  @override
  Future<Map<String, dynamic>?> postCoBroadcastCompat({
    required String streamId,
    required String action,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'streamId': streamId,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    try {
      final res = await postGuestAction(body, streamId: streamId);
      return res.isEmpty ? null : res;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return _extras.coBroadcastAction(
          streamId: streamId,
          action: action,
          userId: userId,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> patchCoBroadcastCompat({
    required String streamId,
    required String action,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      'streamId': streamId,
    };
    try {
      final res = await postGuestAction(body, streamId: streamId);
      return res.isEmpty ? null : res;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        return _extras.patchCoBroadcast(streamId: streamId, action: action);
      }
      rethrow;
    }
  }
}
