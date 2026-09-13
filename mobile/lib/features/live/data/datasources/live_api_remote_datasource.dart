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

  /// `GET /api/live/guest` — oturumlu misafir durumu (Bearer).
  ///
  /// Query: `roomId`, `streamId`, `view` (OpenAPI). Gövde şeması route.ts olmadan
  /// doğrulanmadı; ham JSON döner.
  Future<Map<String, dynamic>> fetchGuestSession({
    String? roomId,
    String? streamId,
    String? view,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveGuest,
      query: {
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (streamId != null && streamId.isNotEmpty) 'streamId': streamId,
        if (view != null && view.isNotEmpty) 'view': view,
      },
      forceRefresh: true,
    );
    if (res.data is Map) {
      return asJsonMap(res.data);
    }
    return {};
  }

  /// `POST /api/live/guest` — `action` tabanlı gövde production probe ile doğrulandı;
  /// tam alan listesi BLOCKED (route.ts yok). [body] çağıran tarafından verilir.
  Future<Map<String, dynamic>> postGuestAction(
    Map<String, dynamic> body, {
    String? roomId,
    String? streamId,
    String? view,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveGuest,
      data: body,
      query: {
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        if (streamId != null && streamId.isNotEmpty) 'streamId': streamId,
        if (view != null && view.isNotEmpty) 'view': view,
      },
    );
    if (res.data is Map) {
      return asJsonMap(res.data);
    }
    return {};
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
