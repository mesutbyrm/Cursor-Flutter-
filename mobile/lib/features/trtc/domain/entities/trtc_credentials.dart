import 'package:equatable/equatable.dart';

/// POST `/api/trtc/token` veya `/api/trtc/usersig` yanıtı.
class TrtcCredentials extends Equatable {
  const TrtcCredentials({
    required this.sdkAppId,
    required this.userId,
    required this.userSig,
    required this.roomId,
    this.expireTime,
    this.role,
    this.trtcRoomId,
    this.numericUid,
  });

  final int sdkAppId;
  final String userId;
  final String userSig;
  final String roomId;
  final int? expireTime;
  final String? role;
  /// Backend kanonik TRTC oda kimliği (`voice_room_<id>`).
  final String? trtcRoomId;
  final int? numericUid;

  /// TRTC `strRoomId` — yalnızca backend değeri.
  String get effectiveStrRoomId {
    final trtc = trtcRoomId?.trim() ?? '';
    if (trtc.isNotEmpty) return trtc;
    return roomId.trim();
  }

  factory TrtcCredentials.fromJson(
    Map<String, dynamic> json, {
    String? requestedRoomId,
  }) {
    var roomId = json['roomId']?.toString().trim() ?? '';
    if (roomId.isEmpty) {
      roomId = json['strRoomId']?.toString().trim() ?? '';
    }
    if (roomId.isEmpty && requestedRoomId != null) {
      roomId = requestedRoomId.trim();
    }
    return TrtcCredentials(
      sdkAppId: (json['sdkAppId'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      userSig: json['userSig']?.toString() ?? json['token']?.toString() ?? '',
      roomId: roomId,
      expireTime: (json['expireTime'] as num?)?.toInt() ??
          (json['expire'] as num?)?.toInt(),
      role: json['role']?.toString(),
      trtcRoomId: json['trtcRoomId']?.toString() ??
          json['trtc_room_id']?.toString(),
      numericUid: (json['numericUid'] as num?)?.toInt() ??
          (json['numeric_uid'] as num?)?.toInt(),
    );
  }

  /// Token `roomId` veya backend `trtcRoomId` ile eşleşir — takma ad kaybı yok.
  bool matchesRoom(String id) {
    final needle = id.trim();
    if (needle.isEmpty) return false;
    if (roomId.trim() == needle) return true;
    final trtc = trtcRoomId?.trim() ?? '';
    return trtc.isNotEmpty && trtc == needle;
  }

  bool get isValid => sdkAppId > 0 && userSig.isNotEmpty && userId.isNotEmpty;

  TrtcCredentials copyWith({
    int? sdkAppId,
    String? userId,
    String? userSig,
    String? roomId,
    int? expireTime,
    String? role,
    String? trtcRoomId,
    int? numericUid,
  }) {
    return TrtcCredentials(
      sdkAppId: sdkAppId ?? this.sdkAppId,
      userId: userId ?? this.userId,
      userSig: userSig ?? this.userSig,
      roomId: roomId ?? this.roomId,
      expireTime: expireTime ?? this.expireTime,
      role: role ?? this.role,
      trtcRoomId: trtcRoomId ?? this.trtcRoomId,
      numericUid: numericUid ?? this.numericUid,
    );
  }

  @override
  List<Object?> get props => [
        sdkAppId,
        userId,
        userSig,
        roomId,
        expireTime,
        role,
        trtcRoomId,
        numericUid,
      ];
}
