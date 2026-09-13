/// Hediye kutusu — `GET/POST /api/gift-box` (ham JSON).
abstract class GiftBoxRepository {
  Future<Map<String, dynamic>> listActive({
    String? roomId,
    String? streamId,
  });

  Future<Map<String, dynamic>> getBox(String boxId);

  Future<Map<String, dynamic>> postAction(
    Map<String, dynamic> body, {
    String? roomId,
    String? streamId,
  });

  Future<Map<String, dynamic>> joinBox(String boxId);

  Future<Map<String, dynamic>> recordShare(Map<String, dynamic> body);

  Future<Map<String, dynamic>> fetchRoomSync(String roomId);

  Future<Map<String, dynamic>> fetchStreamSync(String streamId);
}
