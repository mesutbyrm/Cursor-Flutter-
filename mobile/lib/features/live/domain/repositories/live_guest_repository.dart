import '../live_guest_list_snapshot.dart';

/// Canlı yayın multi-guest — `GET/POST /api/live/guest`, liste `/api/live/guest/list`.
abstract class LiveGuestRepository {
  Future<LiveGuestListSnapshot> fetchGuestList({String? streamId});

  Future<Map<String, dynamic>> fetchGuestSession({
    String? roomId,
    String? streamId,
    String? view,
  });

  /// Ham gövde — UI/datasource katmanının ürettiği `Map` aynen iletilir.
  Future<Map<String, dynamic>> postGuestAction(
    Map<String, dynamic> body, {
    String? roomId,
    String? streamId,
    String? view,
  });

  /// Mevcut co-broadcast UI gövdesi (`action`, `streamId`, opsiyonel `userId`).
  Future<Map<String, dynamic>?> postCoBroadcastCompat({
    required String streamId,
    required String action,
    String? userId,
  });

  /// Mevcut PATCH co-broadcast (`accept` / `reject` / `leave`).
  Future<Map<String, dynamic>?> patchCoBroadcastCompat({
    required String streamId,
    required String action,
  });
}
