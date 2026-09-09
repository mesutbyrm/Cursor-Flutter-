import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_seat_slot.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import 'voice_room_seat_layout.dart';

/// Üretim sesli oda koltuk kapasitesi — backend `seatCount` / `GET /seats`.
const int kDefaultVoiceSeatCount = 8;
const int kMinVoiceSeatCount = 1;
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

bool _isBackendSeatAvailable(
  int seatIndex,
  List<VoiceRoomSeatSlot> seatSlots,
) {
  if (seatSlots.isEmpty) return true;
  for (final slot in seatSlots) {
    if (slot.index != seatIndex) continue;
    return !slot.isLocked;
  }
  return false;
}

/// Progressive "+" — dolu koltuklar + en fazla bir boş "+" (seatCount sınırına kadar).
List<int> progressiveVisibleGuestSeatIndices({
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
  List<VoiceRoomSeatSlot> seatSlots = const [],
  int? configuredSeatCount,
}) {
  final seatCount = resolveVoiceRoomSeatCount(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  if (seatCount <= 1) return const [];

  final maxIndex = voiceRoomLayoutMaxSeatIndex(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  final adminSeat = voiceRoomAdminSeatIndex(
    room: room,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );

  final layout = VoiceRoomSeatLayout(
    room: room,
    presence: presence,
    seatSlots: seatSlots,
  ).build();

  final occupied = <int>[];
  for (var i = 2; i <= maxIndex; i++) {
    if (layout[i] != null) occupied.add(i);
  }
  occupied.sort();

  final micCount = 1 + occupied.length;
  final visible = List<int>.from(occupied);

  if (micCount >= seatCount) return visible;

  for (var i = 2; i <= maxIndex; i++) {
    if (layout[i] != null) continue;
    if (!_isBackendSeatAvailable(i, seatSlots)) continue;
    if (i == adminSeat && !seatSlots.any((s) => s.index == i)) continue;
    visible.add(i);
    break;
  }

  visible.sort();
  return visible;
}

/// Web sahne (VoiceWebOwnerStage) — üst/alt koltuk satırları (progressive).
({List<int> top, List<int> bottom}) voiceWebOwnerSeatRows({
  required VoiceRoomEntity room,
  List<VoiceRoomSeatSlot> seatSlots = const [],
  List<ChatRoomPresence> presence = const [],
  int? configuredSeatCount,
}) {
  final visible = progressiveVisibleGuestSeatIndices(
    room: room,
    presence: presence,
    seatSlots: seatSlots,
    configuredSeatCount: configuredSeatCount,
  );
  if (visible.isEmpty) return (top: const [], bottom: const []);
  final mid = (visible.length / 2).ceil();
  return (top: visible.sublist(0, mid), bottom: visible.sublist(mid));
}

/// Hediye koltuk efektleri için üst sınır (0 tabanlı indeks + 1).
int voiceRoomGiftSeatEffectBound({
  VoiceRoomEntity? room,
  List<VoiceRoomSeatSlot>? seatSlots,
  int? configuredSeatCount,
}) {
  return voiceRoomLayoutMaxSeatIndex(
        room: room,
        seatSlots: seatSlots,
        configuredSeatCount: configuredSeatCount,
      ) +
      1;
}
