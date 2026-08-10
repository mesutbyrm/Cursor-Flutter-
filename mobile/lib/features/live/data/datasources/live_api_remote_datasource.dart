import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/live_guest_list_snapshot.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';

/// Prod `/api/live/*` — PK aktif liste, misafir listesi.
class LiveApiRemoteDataSource {
  LiveApiRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /api/live/pk/active` — düz dizi veya `{ matches: [] }`.
  Future<List<PkRoomMatch>> fetchActivePk() async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.livePkActive,
      forceRefresh: true,
    );
    return parsePkMatchList(res.data);
  }

  /// `GET /api/live/guest/list` — public; `streamId` opsiyonel.
  Future<LiveGuestListSnapshot> fetchGuestList({String? streamId}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveGuestList,
      query: streamId != null && streamId.trim().isNotEmpty
          ? {'streamId': streamId.trim()}
          : null,
      forceRefresh: true,
    );
    final body = res.data;
    if (body is Map) {
      return LiveGuestListSnapshot.fromJson(asJsonMap(body));
    }
    return const LiveGuestListSnapshot();
  }
}
