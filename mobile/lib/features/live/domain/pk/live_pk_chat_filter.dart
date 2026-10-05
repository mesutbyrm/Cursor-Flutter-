import '../../presentation/widgets/broadcast_room/live_room_chat_message.dart';

/// PK overlay sohbet — yalnızca PK sistem gürültüsünü gizle; hediyeler görünür.
bool livePkChatMessageVisible(LiveRoomChatMessage message) {
  // Kullanıcı mesajları asla gizlenmez ("pk at" gibi sohbet metni dahil).
  if (!message.isSystem) return true;
  final t = message.text.toLowerCase();
  if (_pkNoise(t)) return false;
  if (message.user == 'Sistem' || message.user.toLowerCase() == 'system') {
    return !_pkNoise(t);
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
