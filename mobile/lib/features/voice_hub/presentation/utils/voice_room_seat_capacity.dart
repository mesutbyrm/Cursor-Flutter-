import '../../domain/entities/voice_room_seat_slot.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

/// Üretim sesli oda koltuk kapasitesi — backend `seatCount` / `GET /seats`.
const int kDefaultVoiceSeatCount = 8;
const int kMinVoiceSeatCount = 8;
const int kMaxVoiceSeatCount = 15;
/// Koltuk haritası (0 tabanlı slot dizisi) — admin koltuğu dahil üst sınır.
const int kDefaultVoiceSeatMapSize = 12;

int clampVoiceSeatCount(int value) =>
    value.clamp(kMinVoiceSeatCount, kMaxVoiceSeatCount);

/// `GET /seats` dizisi için hedef uzunluk (slot sayısı).
int voiceRoomSeatMapTargetCount({
  int? configuredSeatCount,
  int? fromListLength,
}) {
  final len = fromListLength ?? 0;
  final configured = configuredSeatCount ?? kDefaultVoiceSeatMapSize;
  final target = len > configured ? len : configured;
  return target.clamp(kMinVoiceSeatCount, kMaxVoiceSeatCount);
}

/// UI mikrofon / koltuk sayısı (backend `seatCount`, varsayılan 8).
int resolveVoiceRoomSeatCount({
  VoiceRoomEntity? room,
  List<VoiceRoomSeatSlot>? seatSlots,
  int? configuredSeatCount,
}) {
  final fromLive = configuredSeatCount;
  if (fromLive != null && fromLive > 0) {
    return clampVoiceSeatCount(fromLive);
  }
  final fromRoom = room?.seatCount;
  if (fromRoom != null && fromRoom > 0) {
    return clampVoiceSeatCount(fromRoom);
  }
  if (seatSlots != null && seatSlots.isNotEmpty) {
    final occupied = seatSlots.where((s) => !s.isEmpty).length;
    if (occupied > 0) {
      return clampVoiceSeatCount(seatSlots.length);
    }
  }
  return kDefaultVoiceSeatCount;
}

/// [VoiceRoomSeatLayout] için maksimum koltuk indeksi (dahil).
int voiceRoomLayoutMaxSeatIndex({
  VoiceRoomEntity? room,
  List<VoiceRoomSeatSlot>? seatSlots,
  int? configuredSeatCount,
}) {
  final micSeats = resolveVoiceRoomSeatCount(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  if (micSeats > 10) return 11;
  return micSeats;
}

int? voiceRoomAdminSeatIndex({
  VoiceRoomEntity? room,
  List<VoiceRoomSeatSlot>? seatSlots,
  int? configuredSeatCount,
}) {
  final max = voiceRoomLayoutMaxSeatIndex(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  return max >= 11 ? 11 : null;
}
