import 'package:equatable/equatable.dart';

/// RTC grid koltuğu — host veya konuk.
class LiveGuestSlot extends Equatable {
  const LiveGuestSlot({
    required this.index,
    this.userId,
    this.displayName,
    this.agoraUid,
    this.isHost = false,
    this.cameraOn = true,
    this.micOn = true,
    this.pinned = false,
    this.mutedByHost = false,
  });

  final int index;
  final String? userId;
  final String? displayName;
  final int? agoraUid;
  final bool isHost;
  final bool cameraOn;
  final bool micOn;
  final bool pinned;
  final bool mutedByHost;

  bool get isEmpty => userId == null && agoraUid == null && !isHost;

  LiveGuestSlot copyWith({
    String? userId,
    String? displayName,
    int? agoraUid,
    bool? isHost,
    bool? cameraOn,
    bool? micOn,
    bool? pinned,
    bool? mutedByHost,
    bool clearUser = false,
  }) {
    return LiveGuestSlot(
      index: index,
      userId: clearUser ? null : (userId ?? this.userId),
      displayName: clearUser ? null : (displayName ?? this.displayName),
      agoraUid: clearUser ? null : (agoraUid ?? this.agoraUid),
      isHost: isHost ?? this.isHost,
      cameraOn: cameraOn ?? this.cameraOn,
      micOn: micOn ?? this.micOn,
      pinned: pinned ?? this.pinned,
      mutedByHost: mutedByHost ?? this.mutedByHost,
    );
  }

  @override
  List<Object?> get props =>
      [index, userId, agoraUid, isHost, cameraOn, micOn, pinned, mutedByHost];
}
