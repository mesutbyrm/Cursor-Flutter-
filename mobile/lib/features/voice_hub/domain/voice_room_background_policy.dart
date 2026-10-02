import '../../live/domain/entities/voice_room_entity.dart';
import '../../vip_gold/domain/voice_room_access.dart';

/// Oda arka planı kuralı: yalnızca ücretli (NORMAL 2500 jeton / VIP) odalarda
/// değiştirilebilir. Ücretsiz odada özellik kilitlidir. Site yöneticisi her
/// odada değiştirebilir.
const voiceRoomBackgroundLockedMessage =
    'Oda arka planı yalnızca ücretli (2500 jeton) ve VIP odalarda değiştirilebilir.';

/// Arka plan bölümü bu oda için açık mı (rol/yetki ayrı kontrol edilir).
bool voiceRoomBackgroundUnlocked(
  VoiceRoomEntity room, {
  bool isSiteAdmin = false,
}) =>
    isSiteAdmin || !room.isFreeRoom;
