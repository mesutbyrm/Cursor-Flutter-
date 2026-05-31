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

  /// Chat / presence / DJ — canlifal.com API önce Prisma `id` ile çalışır (slug `ilhamperisi-` gibi).
  String get apiRoomKey {
    final i = id.trim();
    final s = slug.trim();
    if (i.isNotEmpty) return i;
    if (s.isNotEmpty) return s;
    return '';
  }

  /// İkinci deneme anahtarı (id/slug farklıysa).
  String? get apiRoomAlternateKey {
    final s = slug.trim();
    final i = id.trim();
    if (s.isNotEmpty && i.isNotEmpty && s != i) return s;
    return null;
  }

  String get displayTitle => nameTr.trim().isEmpty ? 'Sohbet Odası' : nameTr.trim();

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
