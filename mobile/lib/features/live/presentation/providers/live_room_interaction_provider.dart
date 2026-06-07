import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_providers.dart';

/// Canlı oda etkileşimleri — kalp patlaması, beğeni sayacı (yayın başına).
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

class LiveRoomInteractionNotifier
    extends AutoDisposeFamilyNotifier<LiveRoomInteractionState, String> {
  @override
  LiveRoomInteractionState build(String streamId) => const LiveRoomInteractionState();

  void reset({int initialLikes = 0}) {
    state = LiveRoomInteractionState(likeCount: initialLikes);
  }

  /// Yalnızca kullanıcı çift dokunuşu — sunucuya beğeni gönderir.
  void burstHearts({int likes = 1}) {
    state = state.copyWith(
      likeCount: state.likeCount + likes,
      heartBurstToken: state.heartBurstToken + 1,
    );
    unawaited(_syncLikeToServer(arg, likes));
  }

  /// Görsel kalp animasyonu — API çağrısı yapmaz.
  void pulseHeartsVisual({int bursts = 1}) {
    state = state.copyWith(
      heartBurstToken: state.heartBurstToken + bursts,
    );
  }

  Future<void> loadInitialLikeCount() async {
    try {
      final count =
          await ref.read(liveStreamExtrasProvider).fetchLikeCount(arg);
      if (count > state.likeCount) {
        state = state.copyWith(likeCount: count);
      }
    } catch (_) {}
  }

  Future<void> _syncLikeToServer(String streamId, int likes) async {
    try {
      final total = await ref
          .read(liveStreamExtrasProvider)
          .sendLike(streamId, count: likes);
      if (total > state.likeCount) {
        state = state.copyWith(likeCount: total);
      }
    } catch (_) {}
  }

  void setFollowing(bool v) => state = state.copyWith(following: v);

  void setFollowLoading(bool v) => state = state.copyWith(followLoading: v);
}

final liveRoomInteractionProvider = NotifierProvider.autoDispose
    .family<LiveRoomInteractionNotifier, LiveRoomInteractionState, String>(
  LiveRoomInteractionNotifier.new,
);
