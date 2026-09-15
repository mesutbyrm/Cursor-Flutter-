/// `GET/PUT /api/me/vip-preferences` — üretim `user_vip_preferences` tablosu.
class VipPreferences {
  const VipPreferences({
    this.hideVipBadge = false,
    this.hideOnlineStatus = false,
    this.hideLastSeen = false,
    this.hideProfileVisit = false,
    this.hiddenRoomEntry = false,
    this.hideVipStatus = false,
    this.disableEntranceEffects = false,
    this.muteOthersEntrance = false,
    this.rejected = const [],
  });

  final bool hideVipBadge;
  final bool hideOnlineStatus;
  final bool hideLastSeen;
  final bool hideProfileVisit;
  final bool hiddenRoomEntry;
  final bool hideVipStatus;
  final bool disableEntranceEffects;
  final bool muteOthersEntrance;
  final List<String> rejected;

  factory VipPreferences.fromJson(Map<String, dynamic> json) {
    final rejectedRaw = json['rejected'];
    final rejected = rejectedRaw is List
        ? rejectedRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return VipPreferences(
      hideVipBadge: _bool(json['hideVipBadge']),
      hideOnlineStatus: _bool(json['hideOnlineStatus']),
      hideLastSeen: _bool(json['hideLastSeen']),
      hideProfileVisit: _bool(json['hideProfileVisit']),
      hiddenRoomEntry: _bool(json['hiddenRoomEntry']),
      hideVipStatus: _bool(json['hideVipStatus']),
      disableEntranceEffects: _bool(json['disableEntranceEffects']),
      muteOthersEntrance: _bool(json['muteOthersEntrance']),
      rejected: rejected,
    );
  }

  Map<String, dynamic> toJson() => {
        'hideVipBadge': hideVipBadge,
        'hideOnlineStatus': hideOnlineStatus,
        'hideLastSeen': hideLastSeen,
        'hideProfileVisit': hideProfileVisit,
        'hiddenRoomEntry': hiddenRoomEntry,
        'hideVipStatus': hideVipStatus,
        'disableEntranceEffects': disableEntranceEffects,
        'muteOthersEntrance': muteOthersEntrance,
      };

  VipPreferences copyWith({
    bool? hideVipBadge,
    bool? hideOnlineStatus,
    bool? hideLastSeen,
    bool? hideProfileVisit,
    bool? hiddenRoomEntry,
    bool? hideVipStatus,
    bool? disableEntranceEffects,
    bool? muteOthersEntrance,
    List<String>? rejected,
  }) {
    return VipPreferences(
      hideVipBadge: hideVipBadge ?? this.hideVipBadge,
      hideOnlineStatus: hideOnlineStatus ?? this.hideOnlineStatus,
      hideLastSeen: hideLastSeen ?? this.hideLastSeen,
      hideProfileVisit: hideProfileVisit ?? this.hideProfileVisit,
      hiddenRoomEntry: hiddenRoomEntry ?? this.hiddenRoomEntry,
      hideVipStatus: hideVipStatus ?? this.hideVipStatus,
      disableEntranceEffects:
          disableEntranceEffects ?? this.disableEntranceEffects,
      muteOthersEntrance: muteOthersEntrance ?? this.muteOthersEntrance,
      rejected: rejected ?? this.rejected,
    );
  }

  static bool _bool(dynamic v) => v == true || v == 'true' || v == 1;
}
