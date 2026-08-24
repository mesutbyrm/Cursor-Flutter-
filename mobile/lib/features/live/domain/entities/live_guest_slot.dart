import 'package:equatable/equatable.dart';

/// RTC grid koltuğu — host veya konuk.
class LiveGuestSlot extends Equatable {
  const LiveGuestSlot({
    required this.index,
    this.userId,
    this.displayName,
    this.rtcUserId,
    this.isHost = false,
    this.cameraOn = true,
    this.micOn = true,
    this.pinned = false,
    this.mutedByHost = false,
    this.jetonEarned = 0,
  });

  final int index;
  final String? userId;
  final String? displayName;
  final String? rtcUserId;
  final bool isHost;
  final bool cameraOn;
  final bool micOn;
  final bool pinned;
  final bool mutedByHost;
  final int jetonEarned;

  bool get isEmpty => userId == null && rtcUserId == null && !isHost;

  LiveGuestSlot copyWith({
    String? userId,
    String? displayName,
    String? rtcUserId,
    bool? isHost,
    bool? cameraOn,
    bool? micOn,
    bool? pinned,
    bool? mutedByHost,
    int? jetonEarned,
    bool clearUser = false,
  }) {
    return LiveGuestSlot(
      index: index,
      userId: clearUser ? null : (userId ?? this.userId),
      displayName: clearUser ? null : (displayName ?? this.displayName),
      rtcUserId: clearUser ? null : (rtcUserId ?? this.rtcUserId),
      isHost: isHost ?? this.isHost,
      cameraOn: cameraOn ?? this.cameraOn,
      micOn: micOn ?? this.micOn,
      pinned: pinned ?? this.pinned,
      mutedByHost: mutedByHost ?? this.mutedByHost,
      jetonEarned: jetonEarned ?? this.jetonEarned,
    );
  }

  @override
  List<Object?> get props => [
        index,
        userId,
        rtcUserId,
        isHost,
        cameraOn,
        micOn,
        pinned,
        mutedByHost,
        jetonEarned,
      ];
}
