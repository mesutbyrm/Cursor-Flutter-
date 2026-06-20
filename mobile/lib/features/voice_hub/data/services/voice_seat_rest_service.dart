import '../../../../core/network/api_exception.dart';
import '../datasources/chat_room_remote_datasource.dart';

/// Koltuk / mikrofon / rol — REST mutasyonları (socket değil).
///
/// `takeSeat` / `leaveSeat` gövdeleri `api/src/routes/chat_rooms.ts` →
/// `handleAssignSeat` ile uyumludur: `{ seatIndex, userId?, targetUserId? }`.
class VoiceSeatRestService {
  VoiceSeatRestService(this._remote);

  final ChatRoomRemoteDataSource _remote;

  /// PATCH/POST `/api/chat/rooms/:roomId/seats` — `handleAssignSeat` body.
  Future<void> takeSeat(String roomId, int seatIndex, {String? userId}) async {
    await _remote.assignSeat(
      roomKey: roomId,
      seatIndex: seatIndex,
      userId: userId,
    );
  }

  /// Koltuktan in — üretim davranışı doğrulanmadı.
  ///
  /// Yerel `api/` aynasında yalnızca `assignSeat(seatIndex 1–11)` var;
  /// `seatIndex: 0` bile 1'e yuvarlanır. Üretimde farklı bir sözleşme olabilir.
  Future<void> leaveSeat(String roomId) async {
    // VARSAYIM: endpoint doğrulanmadı — üretimde null/-1 veya ayrı route olabilir.
    throw UnimplementedError(
      'leaveSeat endpoint doğrulanmadı — chat_rooms.ts ve canlifal.com /seats kontrol et',
    );
  }

  /// Mikrofon aç/kapa — endpoint doğrulanmadı.
  ///
  /// `chat_rooms.ts` içinde `mute` / `isSpeaking` route'u aranmalı;
  /// `approveSpeak()` konuşma kuyruğu mu yoksa doğrudan mic toggle mı belirsiz.
  Future<void> toggleMic(String roomId, bool muted) async {
    throw UnimplementedError(
      'mic endpoint doğrulanmadı — chat_rooms.ts içinde mute/isSpeaking route ara',
    );
  }

  /// Rol değişikliği — endpoint doğrulanmadı.
  ///
  /// Mobil `rolePath`: `/api/chat/rooms/:roomId/roles` (yerel `api/` aynasında yok).
  Future<void> changeRole(String roomId, String role) async {
    throw UnimplementedError(
      'role endpoint doğrulanmadı — chat_rooms.ts ve /roles route kontrol et',
    );
  }

  /// UI için kısa hata metni.
  static String placeholderMessage(Object error) {
    if (error is UnimplementedError) {
      return 'Bu özellik yakında — sunucu uç noktası henüz doğrulanmadı.';
    }
    return ApiException.userMessage(error);
  }
}
