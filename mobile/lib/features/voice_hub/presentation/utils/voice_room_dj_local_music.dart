/// Sesli oda müzik modu.
///
/// Müzik yalnız oda sahibi / DJ'in telefonundaki dosyadan TRTC yayınına
/// karışır; dinleyiciler onu DJ'in sesi gibi duyar. Uygulama içi YouTube /
/// akış oynatma kapalıdır (senkron kayması, donma ve «kapattım geri geldi»
/// sorunlarının kaynağıydı).
abstract final class VoiceRoomDjLocalMusic {
  static const enabled = true;
}
