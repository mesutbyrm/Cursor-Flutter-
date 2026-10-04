import '../../live/domain/entities/voice_room_entity.dart';

/// Oda arka planı: oda sahibi / yetkili, ücretsiz oda dahil HER odada arka plan
/// yükleyebilir veya sunucudaki hazır görsellerden seçebilir (eski «yalnızca
/// ücretli oda» kilidi kaldırıldı). Rol/yetki ayrı kontrol edilir.
const voiceRoomBackgroundLockedMessage =
    'Oda arka planını değiştirme yetkiniz yok.';

/// Arka plan bölümü bu oda için açık mı (rol/yetki ayrı kontrol edilir).
bool voiceRoomBackgroundUnlocked(
  VoiceRoomEntity room, {
  bool isSiteAdmin = false,
}) =>
    true;
