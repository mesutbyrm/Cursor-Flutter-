/// Sesli oda müzik modu.
///
/// - `!istek şarkıcı şarkı`: istek oda sahibi / DJ'e açılır pencere olarak
///   gider; DJ telefonundaki dosyayı TRTC yayınına karıştırır.
/// - Sağ paneldeki müzik kısmından istenen şarkı ise sunucu kuyruğundan
///   uygulama içinde çalar ve son iki koltuğun yerindeki kutuda görünür.
abstract final class VoiceRoomDjLocalMusic {
  /// !istek → DJ isteği (açılır pencere + DJ telefonundan çalma).
  static const enabled = true;

  /// Uygulama içi (sunucu kuyruğu) oynatmayı tamamen kapatır. Sağ panel
  /// istekleri kutuda çalsın diye kapalı değil.
  static const blockInAppPlayback = false;
}
