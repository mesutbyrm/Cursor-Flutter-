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
  });

  final int sdkAppId;
  final String userId;
  final String userSig;
  final String roomId;
  final int? expireTime;
  final String? role;

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
      userSig: json['userSig']?.toString() ?? '',
      roomId: roomId,
      expireTime: (json['expireTime'] as num?)?.toInt() ??
          (json['expire'] as num?)?.toInt(),
      role: json['role']?.toString(),
    );
  }

  bool matchesRoom(String id) => roomId == id.trim();

  bool get isValid => sdkAppId > 0 && userSig.isNotEmpty && userId.isNotEmpty;

  TrtcCredentials copyWith({
    int? sdkAppId,
    String? userId,
    String? userSig,
    String? roomId,
    int? expireTime,
    String? role,
  }) {
    return TrtcCredentials(
      sdkAppId: sdkAppId ?? this.sdkAppId,
      userId: userId ?? this.userId,
      userSig: userSig ?? this.userSig,
      roomId: roomId ?? this.roomId,
      expireTime: expireTime ?? this.expireTime,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props =>
      [sdkAppId, userId, userSig, roomId, expireTime, role];
}
