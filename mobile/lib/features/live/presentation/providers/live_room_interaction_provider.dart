import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Canlı oda etkileşimleri — kalp patlaması, beğeni sayacı.
class LiveRoomInteractionState {
  const LiveRoomInteractionState({
    this.likeCount = 0,
    this.heartBurstToken = 0,
    this.following = false,
    this.followLoading = false,
  });

  final int likeCount;
  final int heartBurstToken;
  final bool following;
  final bool followLoading;

  LiveRoomInteractionState copyWith({
    int? likeCount,
    int? heartBurstToken,
    bool? following,
    bool? followLoading,
  }) {
    return LiveRoomInteractionState(
      likeCount: likeCount ?? this.likeCount,
      heartBurstToken: heartBurstToken ?? this.heartBurstToken,
      following: following ?? this.following,
      followLoading: followLoading ?? this.followLoading,
    );
  }
}

class LiveRoomInteractionNotifier extends Notifier<LiveRoomInteractionState> {
  @override
  LiveRoomInteractionState build() => const LiveRoomInteractionState();

  void reset({int initialLikes = 12500}) {
    state = LiveRoomInteractionState(likeCount: initialLikes);
  }

  void burstHearts({int likes = 1}) {
    state = state.copyWith(
      likeCount: state.likeCount + likes,
      heartBurstToken: state.heartBurstToken + 1,
    );
  }

  void setFollowing(bool v) => state = state.copyWith(following: v);

  void setFollowLoading(bool v) => state = state.copyWith(followLoading: v);
}

final liveRoomInteractionProvider =
    NotifierProvider.autoDispose<LiveRoomInteractionNotifier, LiveRoomInteractionState>(
  LiveRoomInteractionNotifier.new,
);
