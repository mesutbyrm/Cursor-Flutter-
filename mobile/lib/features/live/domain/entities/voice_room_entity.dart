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
    this.category,
    this.onlineCount = 0,
    this.userCount = 0,
    this.backgroundImageUrl,
    this.ownerName,
    this.ownerAvatarUrl,
    this.ownerId,
    this.activeDjId,
    this.djUserIds = const [],
    this.recentUserAvatars = const [],
    this.isVip,
    this.roomType,
    this.isLocked,
    this.hasPassword,
    this.seatCount,
    this.maxUsers,
  });

  final String id;
  final String slug;
  final String nameTr;
  final String? descTr;
  final String? rulesTr;
  final String? icon;
  /// Keşfet / `POST /rooms/create` — `chat`, `music`, `love`, …
  final String? category;
  final int onlineCount;
  final int userCount;
  final String? backgroundImageUrl;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final String? ownerId;
  final String? activeDjId;
  final List<String> djUserIds;
  final List<String> recentUserAvatars;
  final bool? isVip;
  final String? roomType;
  /// Sunucu: oda kilitli / şifre gerekli.
  final bool? isLocked;
  final bool? hasPassword;
  /// Backend `seatCount` — koltuk haritası boyutu.
  final int? seatCount;
  final int? maxUsers;

  int get displayOnline => onlineCount > 0 ? onlineCount : userCount;

  /// REST / Socket — yalnızca Prisma `id` (cuid); slug kullanılmaz.
  String get apiRoomKey => id.trim();

  /// Riverpod `voiceRoomLiveProvider` ailesi — yalnızca oda kimliği (metadata değişince dispose olmasın).
  String get liveKey => apiRoomKey;

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
        category: category,
        backgroundImageUrl: backgroundImageUrl,
        ownerName: ownerName,
        ownerAvatarUrl: ownerAvatarUrl,
        ownerId: ownerId,
        activeDjId: activeDjId,
        djUserIds: djUserIds,
        recentUserAvatars: recentUserAvatars,
        isVip: isVip,
        roomType: roomType,
        isLocked: isLocked,
        hasPassword: hasPassword,
        seatCount: seatCount,
        maxUsers: maxUsers,
      );

  VoiceRoomEntity copyWith({
    int? onlineCount,
    int? userCount,
    bool? isLocked,
    bool? hasPassword,
    int? seatCount,
    int? maxUsers,
    String? category,
    String? nameTr,
    String? descTr,
    String? rulesTr,
  }) {
    return VoiceRoomEntity(
      id: id,
      slug: slug,
      nameTr: nameTr ?? this.nameTr,
      descTr: descTr ?? this.descTr,
      rulesTr: rulesTr ?? this.rulesTr,
      icon: icon,
      category: category ?? this.category,
      onlineCount: onlineCount ?? this.onlineCount,
      userCount: userCount ?? this.userCount,
      backgroundImageUrl: backgroundImageUrl,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
      ownerId: ownerId,
      activeDjId: activeDjId,
      djUserIds: djUserIds,
      recentUserAvatars: recentUserAvatars,
      isVip: isVip,
      roomType: roomType,
      isLocked: isLocked ?? this.isLocked,
      hasPassword: hasPassword ?? this.hasPassword,
      seatCount: seatCount ?? this.seatCount,
      maxUsers: maxUsers ?? this.maxUsers,
    );
  }

  @override
  List<Object?> get props => [
        id,
        slug,
        nameTr,
        descTr,
        rulesTr,
        icon,
        category,
        onlineCount,
        userCount,
        backgroundImageUrl,
        ownerName,
        ownerAvatarUrl,
        ownerId,
        activeDjId,
        djUserIds,
        recentUserAvatars,
        isVip,
        roomType,
        isLocked,
        hasPassword,
        seatCount,
        maxUsers,
      ];
}
