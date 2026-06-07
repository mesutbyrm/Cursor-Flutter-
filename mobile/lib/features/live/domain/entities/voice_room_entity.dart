import 'package:equatable/equatable.dart';

/// `/api/chat/rooms` satırı — web ile aynı oda listesi.
class VoiceRoomEntity extends Equatable {
  const VoiceRoomEntity({
    required this.id,
    required this.slug,
    required this.nameTr,
    this.descTr,
    this.rulesTr,
    this.icon,
    this.onlineCount = 0,
    this.userCount = 0,
    this.backgroundImageUrl,
    this.ownerName,
    this.ownerAvatarUrl,
    this.ownerId,
    this.activeDjId,
    this.djUserIds = const [],
    this.recentUserAvatars = const [],
  });

  final String id;
  final String slug;
  final String nameTr;
  final String? descTr;
  final String? rulesTr;
  final String? icon;
  final int onlineCount;
  final int userCount;
  final String? backgroundImageUrl;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? ownerId;
  final String? activeDjId;
  final List<String> djUserIds;
  final List<String> recentUserAvatars;

  int get displayOnline => onlineCount > 0 ? onlineCount : userCount;

  /// REST / Socket — yalnızca Prisma `id` (cuid); slug kullanılmaz.
  String get apiRoomKey => id.trim();

  /// Tencent TRTC kanal adı — web ile aynı: `voice_room_{id}`.
  String get trtcRoomId {
    final i = id.trim();
    if (i.isEmpty) return '';
    return 'voice_room_$i';
  }

  String get displayTitle => nameTr.trim().isEmpty ? 'Sohbet Odası' : nameTr.trim();

  /// Riverpod oturum anahtarı — online sayısı değişince provider yeniden kurulmasın.
  VoiceRoomEntity get stableSessionKey => VoiceRoomEntity(
        id: id,
        slug: slug,
        nameTr: nameTr,
        descTr: descTr,
        rulesTr: rulesTr,
        icon: icon,
        backgroundImageUrl: backgroundImageUrl,
        ownerName: ownerName,
        ownerAvatarUrl: ownerAvatarUrl,
        ownerId: ownerId,
        activeDjId: activeDjId,
        djUserIds: djUserIds,
        recentUserAvatars: recentUserAvatars,
      );

  @override
  List<Object?> get props => [
        id,
        slug,
        nameTr,
        descTr,
        rulesTr,
        icon,
        onlineCount,
        userCount,
        backgroundImageUrl,
        ownerName,
        ownerAvatarUrl,
        ownerId,
        activeDjId,
        djUserIds,
        recentUserAvatars,
      ];
}
