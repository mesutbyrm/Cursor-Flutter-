import '../datasources/chat_room_remote_datasource.dart';

/// Koltuk REST mutasyonları (socket değil).
///
/// Mikrofon aç/kapa client-side TRTC/LiveKit üzerinden yönetilir; backend'de
/// `toggleMic` / `isSpeaking` route'u yok.
///
/// Rol atama: [ChatRoomRemoteDataSource.assignRole] — provider üzerinden çağırın.
class VoiceSeatRestService {
  VoiceSeatRestService(this._remote);

  final ChatRoomRemoteDataSource _remote;

  /// PATCH/POST `/api/chat/rooms/:roomId/seats`
  Future<void> takeSeat(String roomId, int seatIndex, {String? userId}) async {
    await _remote.assignSeat(
      roomKey: roomId,
      seatIndex: seatIndex,
      userId: userId,
    );
  }

  /// Koltuktan in — üretim davranışı doğrulanmadı (`seatIndex: -1` vb.).
  Future<void> leaveSeat(String roomId) async {
    throw UnimplementedError(
      'leaveSeat endpoint doğrulanmadı — üretim /seats body (seatIndex: -1) kontrol et',
    );
  }
}
