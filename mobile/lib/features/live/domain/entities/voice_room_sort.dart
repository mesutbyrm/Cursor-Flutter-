import 'voice_room_entity.dart';

/// Sohbet odalarını çevrimiçi kullanıcı sayısına göre sıralar (en kalabalık önce).
List<VoiceRoomEntity> sortVoiceRoomsByPopularity(List<VoiceRoomEntity> rooms) {
  final copy = List<VoiceRoomEntity>.from(rooms);
  copy.sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
  return copy;
}
