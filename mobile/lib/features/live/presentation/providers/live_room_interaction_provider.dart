import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_providers.dart';

/// Canlı oda etkileşimleri — kalp patlaması, beğeni sayacı (yayın başına).
class LiveRoomInteractionState {
  const LiveRoomInteractionState({
    this.likeCount = 0,
    this.heartBurstToken = 0,
    this.superLikeToken = 0,
    this.emojiRainToken = 0,
    this.applauseToken = 0,
    this.following = false,
    this.followLoading = false,
  });

  final int likeCount;
  final int heartBurstToken;
  final int superLikeToken;
  final int emojiRainToken;
  final int applauseToken;
  final bool following;
  final bool followLoading;

  LiveRoomInteractionState copyWith({
    int? likeCount,
    int? heartBurstToken,
    int? superLikeToken,
    int? emojiRainToken,
    int? applauseToken,
    bool? following,
    bool? followLoading,
  }) {
    return LiveRoomInteractionState(
      likeCount: likeCount ?? this.likeCount,
      heartBurstToken: heartBurstToken ?? this.heartBurstToken,
      superLikeToken: superLikeToken ?? this.superLikeToken,
      emojiRainToken: emojiRainToken ?? this.emojiRainToken,
      applauseToken: applauseToken ?? this.applauseToken,
      following: following ?? this.following,
      followLoading: followLoading ?? this.followLoading,
    );
  }
}

class LiveRoomInteractionNotifier
    extends AutoDisposeFamilyNotifier<LiveRoomInteractionState, String> {
  DateTime? _lastLikeSync;
  static const _likeCooldown = Duration(milliseconds: 900);

  @override
  LiveRoomInteractionState build(String streamId) => const LiveRoomInteractionState();

  void reset({int initialLikes = 0}) {
    state = LiveRoomInteractionState(likeCount: initialLikes);
  }

  /// Yalnızca kullanıcı çift dokunuşu — sunucuya beğeni gönderir.
  void burstHearts({int likes = 1}) {
    if (!_canSyncLike()) return;
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

  /// Signal / polling ile gelen toplam beğeni — API çağrısı yapmaz.
  void syncRemoteLikeCount(int total, {bool pulse = false}) {
    if (total <= state.likeCount) return;
    state = state.copyWith(
      likeCount: total,
      heartBurstToken: pulse ? state.heartBurstToken + 1 : state.heartBurstToken,
    );
  }

  void triggerSuperLike() {
    if (!_canSyncLike()) return;
    state = state.copyWith(
      likeCount: state.likeCount + 5,
      superLikeToken: state.superLikeToken + 1,
      heartBurstToken: state.heartBurstToken + 1,
    );
    unawaited(_syncLikeToServer(arg, 5));
  }

  void triggerEmojiRain() {
    state = state.copyWith(emojiRainToken: state.emojiRainToken + 1);
  }

  void triggerApplause() {
    state = state.copyWith(applauseToken: state.applauseToken + 1);
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

  bool _canSyncLike() {
    final now = DateTime.now();
    if (_lastLikeSync != null &&
        now.difference(_lastLikeSync!) < _likeCooldown) {
      return false;
    }
    _lastLikeSync = now;
    return true;
  }
}

final liveRoomInteractionProvider = NotifierProvider.autoDispose
    .family<LiveRoomInteractionNotifier, LiveRoomInteractionState, String>(
  LiveRoomInteractionNotifier.new,
);
