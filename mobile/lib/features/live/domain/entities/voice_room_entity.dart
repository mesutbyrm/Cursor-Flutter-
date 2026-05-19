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
    this.userCount = 0,
    this.backgroundImageUrl,
    this.ownerName,
    this.ownerAvatarUrl,
    this.recentUserAvatars = const [],
  });

  final String id;
  final String slug;
  final String nameTr;
  final String? descTr;
  final String? icon;
  final int onlineCount;
  final int userCount;
  final String? backgroundImageUrl;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final List<String> recentUserAvatars;

  int get displayOnline => onlineCount > 0 ? onlineCount : userCount;

  @override
  List<Object?> get props => [
        id,
        slug,
        nameTr,
        descTr,
        icon,
        onlineCount,
        userCount,
        backgroundImageUrl,
        ownerName,
        ownerAvatarUrl,
        recentUserAvatars,
      ];
}
