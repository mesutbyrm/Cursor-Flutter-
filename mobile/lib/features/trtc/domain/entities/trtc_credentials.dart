import 'package:equatable/equatable.dart';

/// POST `/api/trtc/usersig` yanıtı.
class TrtcCredentials extends Equatable {
  const TrtcCredentials({
    required this.sdkAppId,
    required this.userId,
    required this.userSig,
    required this.roomId,
  });

  final int sdkAppId;
  final String userId;
  final String userSig;
  final String roomId;

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
    );
  }

  bool matchesRoom(String id) => roomId == id.trim();

  @override
  List<Object?> get props => [sdkAppId, userId, userSig, roomId];
}
