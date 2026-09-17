import '../../presentation/widgets/broadcast_room/live_room_chat_message.dart';

/// PK overlay sohbet — sistem/PK/hediye satırlarını gizle.
bool livePkChatMessageVisible(LiveRoomChatMessage message) {
  if (!message.isSystem) {
    final t = message.text.toLowerCase();
    if (_pkNoise(t)) return false;
    if (_giftNoise(t)) return false;
    return true;
  }
  final t = message.text.toLowerCase();
  if (_pkNoise(t) || _giftNoise(t)) return false;
  if (message.user == 'Sistem' || message.user.toLowerCase() == 'system') {
    return !_giftNoise(t) && !_pkNoise(t);
  }
  return true;
}

bool _pkNoise(String t) {
  if (t.contains('pk ')) return true;
  if (t.contains('pk başlad')) return true;
  if (t.contains('pk bitti')) return true;
  if (t.contains('pk devam')) return true;
  if (t.contains('pk kabul')) return true;
  if (t.contains('pk redd')) return true;
  if (t.contains('pk skor')) return true;
  if (t.contains(' kazandı') && t.contains('pk')) return true;
  if (t.contains('saniye kaldı') && t.contains('pk')) return true;
  return false;
}

bool _giftNoise(String t) {
  if (t.startsWith('gift-')) return true;
  if (t.contains('hediye gönderdi')) return true;
  if (t.contains('değerinde') && t.contains('gönderdi')) return true;
  if (t.contains('jeton') && t.contains('gönderdi')) return true;
  return false;
}
