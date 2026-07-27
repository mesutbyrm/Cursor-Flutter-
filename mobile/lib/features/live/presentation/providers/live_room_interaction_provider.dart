import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import 'live_providers.dart';

/// Canlı oda etkileşimleri — kalp patlaması, beğeni sayacı (yayın başına).
class LiveRoomInteractionState {
  const LiveRoomInteractionState({
    this.likeCount = 0,
    this.myLikeCount = 0,
    this.userLikeCounts = const {},
    this.heartBurstToken = 0,
    this.superLikeToken = 0,
    this.emojiRainToken = 0,
    this.applauseToken = 0,
    this.following = false,
    this.followLoading = false,
  });

  final int likeCount;
  /// Bu oturumda mevcut kullanıcının attığı beğeni.
  final int myLikeCount;
  /// userId → beğeni sayısı (SSE/signal ile senkron).
  final Map<String, int> userLikeCounts;
  final int heartBurstToken;
  final int superLikeToken;
  final int emojiRainToken;
  final int applauseToken;
  final bool following;
  final bool followLoading;

  LiveRoomInteractionState copyWith({
    int? likeCount,
    int? myLikeCount,
    Map<String, int>? userLikeCounts,
    int? heartBurstToken,
    int? superLikeToken,
    int? emojiRainToken,
    int? applauseToken,
    bool? following,
    bool? followLoading,
  }) {
    return LiveRoomInteractionState(
      likeCount: likeCount ?? this.likeCount,
      myLikeCount: myLikeCount ?? this.myLikeCount,
      userLikeCounts: userLikeCounts ?? this.userLikeCounts,
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
  static const _likeCooldown = Duration(milliseconds: 350);

  @override
  LiveRoomInteractionState build(String streamId) => const LiveRoomInteractionState();

  void reset({int initialLikes = 0}) {
    state = LiveRoomInteractionState(likeCount: initialLikes);
  }

  /// Yalnızca kullanıcı çift dokunuşu — sunucuya beğeni gönderir.
  void burstHearts({int likes = 1, String? userId}) {
    if (!_canSyncLike()) return;
    final uid = userId?.trim() ?? '';
    final nextUserCounts = Map<String, int>.from(state.userLikeCounts);
    if (uid.isNotEmpty) {
      nextUserCounts[uid] = (nextUserCounts[uid] ?? 0) + likes;
    }
    state = state.copyWith(
      likeCount: state.likeCount + likes,
      myLikeCount: state.myLikeCount + likes,
      userLikeCounts: nextUserCounts,
      heartBurstToken: state.heartBurstToken + 1,
    );
    unawaited(_syncLikeToServer(arg, likes, userId: uid));
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

  void applyRemoteUserLike({
    required String userId,
    int delta = 1,
    int? userTotal,
    int? streamTotal,
  }) {
    final uid = userId.trim();
    if (uid.isEmpty && streamTotal == null) return;
    final counts = Map<String, int>.from(state.userLikeCounts);
    if (uid.isNotEmpty) {
      final next = userTotal ?? ((counts[uid] ?? 0) + delta);
      counts[uid] = next;
    }
    final total = streamTotal ?? (state.likeCount + delta);
    state = state.copyWith(
      likeCount: total > state.likeCount ? total : state.likeCount,
      userLikeCounts: counts,
      heartBurstToken: state.heartBurstToken + 1,
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

  /// Yayıncı takip durumu — oda açılışında yüklenir; zaten takipteyse buton gizlenir.
  Future<void> loadFollowingStatus(String hostUserId) async {
    final id = hostUserId.trim();
    if (id.isEmpty) return;
    try {
      final profile = await ref.read(profileRepositoryProvider).getUser(id);
      state = state.copyWith(following: profile.isFollowing);
    } catch (_) {}
  }

  Future<void> _syncLikeToServer(String streamId, int likes, {String? userId}) async {
    try {
      final total = await ref
          .read(liveStreamExtrasProvider)
          .sendLike(streamId, count: likes);
      if (total > state.likeCount) {
        state = state.copyWith(likeCount: total);
      }
      final uid = userId?.trim() ?? '';
      if (uid.isNotEmpty) {
        unawaited(
          ref.read(liveStreamExtrasProvider).postSignal(
                streamId: streamId,
                type: 'like',
                data: {
                  'userId': uid,
                  'count': likes,
                  'userLikeCount': state.userLikeCounts[uid] ?? likes,
                  'likeCount': state.likeCount,
                },
              ),
        );
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
