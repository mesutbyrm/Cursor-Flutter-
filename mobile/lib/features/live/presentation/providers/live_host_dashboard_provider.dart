import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gifts/live_gift_controller.dart';
import '../gifts/providers/live_gift_providers.dart';
import 'live_room_interaction_provider.dart';
import 'live_room_providers.dart';

/// Yayıncı gelir paneli — mevcut API/SSE verilerinden türetilir.
class LiveHostDashboardState {
  const LiveHostDashboardState({
    this.totalJeton = 0,
    this.giftCount = 0,
    this.viewerCount = 0,
    this.likeCount = 0,
    this.followerDelta = 0,
    this.perMinuteJeton = 0,
    this.perHourJeton = 0,
    this.revenueHistory = const [],
    this.viewerHistory = const [],
    this.giftHistory = const [],
  });

  final int totalJeton;
  final int giftCount;
  final int viewerCount;
  final int likeCount;
  final int followerDelta;
  final int perMinuteJeton;
  final int perHourJeton;
  final List<int> revenueHistory;
  final List<int> viewerHistory;
  final List<int> giftHistory;
}

class LiveHostDashboardNotifier
    extends AutoDisposeFamilyNotifier<LiveHostDashboardState, String> {
  final List<int> _revenueSamples = [];
  final List<int> _viewerSamples = [];
  final List<int> _giftSamples = [];
  Timer? _tick;
  DateTime? _startedAt;
  int _lastGiftCount = 0;

  @override
  LiveHostDashboardState build(String streamId) {
    _startedAt = DateTime.now();
    ref.onDispose(() => _tick?.cancel());
    _tick = Timer.periodic(const Duration(seconds: 5), (_) => _sample(streamId));
    ref.listen(liveGiftControllerProvider, (_, __) => _sample(streamId));
    ref.listen(liveRoomProvider(streamId), (_, __) => _sample(streamId));
    ref.listen(liveRoomInteractionProvider(streamId), (_, __) => _sample(streamId));
    Future.microtask(() => _sample(streamId));
    return const LiveHostDashboardState();
  }

  void _sample(String streamId) {
    final gift = ref.read(liveGiftControllerProvider);
    final room = ref.read(liveRoomProvider(streamId));
    final interaction = ref.read(liveRoomInteractionProvider(streamId));

    final jeton = gift.streamerEarnings ?? 0;
    final gifts = gift.notifications.length;
    final viewers = room.viewerCount;
    final likes = interaction.likeCount;

    _revenueSamples.add(jeton);
    _viewerSamples.add(viewers);
    _giftSamples.add(gifts);
    if (_revenueSamples.length > 24) _revenueSamples.removeAt(0);
    if (_viewerSamples.length > 24) _viewerSamples.removeAt(0);
    if (_giftSamples.length > 24) _giftSamples.removeAt(0);

    final elapsedMin =
        DateTime.now().difference(_startedAt ?? DateTime.now()).inMinutes.clamp(1, 9999);
    final perMin = (jeton / elapsedMin).round();
    final perHour = (perMin * 60).round();

    _lastGiftCount = gifts;

    state = LiveHostDashboardState(
      totalJeton: jeton,
      giftCount: gifts,
      viewerCount: viewers,
      likeCount: likes,
      perMinuteJeton: perMin,
      perHourJeton: perHour,
      revenueHistory: List.unmodifiable(_revenueSamples),
      viewerHistory: List.unmodifiable(_viewerSamples),
      giftHistory: List.unmodifiable(_giftSamples),
      followerDelta: interaction.following ? 1 : 0,
    );
  }
}

final liveHostDashboardProvider = AutoDisposeNotifierProviderFamily<
    LiveHostDashboardNotifier,
    LiveHostDashboardState,
    String>(LiveHostDashboardNotifier.new);
