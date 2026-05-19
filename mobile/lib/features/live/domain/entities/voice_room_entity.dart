import 'package:equatable/equatable.dart';

/// `/api/chat/rooms` satırı — web ile aynı oda listesi.
class VoiceRoomEntity extends Equatable {
  const VoiceRoomEntity({
    required this.id,
    required this.slug,
    required this.nameTr,
    this.descTr,
    this.icon,
    this.onlineCount = 0,
    this.backgroundImageUrl,
    this.ownerName,
  });

  final String id;
  final String slug;
  final String nameTr;
  final String? descTr;
  final String? icon;
  final int onlineCount;
  final String? backgroundImageUrl;
  final String? ownerName;

  @override
  List<Object?> get props =>
      [id, slug, nameTr, descTr, icon, onlineCount, backgroundImageUrl, ownerName];
}
