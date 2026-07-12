import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/live_guest_list_snapshot.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';

/// Prod `/api/live/*` — PK aktif liste, misafir listesi, sweep (cron).
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

  /// `POST /api/live/pk/sweep` — zamanlanmış görev / admin; `x-cron-key` header.
  Future<bool> sweepPk({required String cronKey}) async {
    final key = cronKey.trim();
    if (key.isEmpty) {
      throw const ApiException('Cron anahtarı gerekli.');
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.livePkSweep,
      data: const {},
      options: Options(headers: {'x-cron-key': key}),
    );
    final body = res.data;
    if (body is Map && body['ok'] == true) return true;
    if (body is Map && body['success'] == true) return true;
    return res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
  }
}
