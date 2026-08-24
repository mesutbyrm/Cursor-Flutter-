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

  /// Koltuk değiştir — `action: swap` veya take fallback.
  Future<void> swapSeat(String roomId, int seatIndex) async {
    await _remote.swapSeat(roomKey: roomId, seatIndex: seatIndex);
  }

  /// PATCH/POST `/api/chat/rooms/:roomId/seats`
  Future<void> takeSeat(String roomId, int seatIndex, {String? userId}) async {
    await _remote.assignSeat(
      roomKey: roomId,
      seatIndex: seatIndex,
      userId: userId,
    );
  }

  /// Koltuktan in — `seatIndex: -1` ile üretim `/seats` uçları.
  Future<void> leaveSeat(String roomId, {String? userId}) async {
    await _remote.clearSeat(roomKey: roomId, userId: userId);
  }
}
