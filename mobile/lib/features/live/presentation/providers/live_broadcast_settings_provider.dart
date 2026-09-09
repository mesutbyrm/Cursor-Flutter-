import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_guest_layout.dart';

/// Yayın ayarları — yorum, hediye, PK, konuk ve grid kapasitesi.
class LiveBroadcastSettings {
  const LiveBroadcastSettings({
    this.commentsEnabled = true,
    this.giftsEnabled = true,
    this.fortuneRequestsEnabled = true,
    this.pkEnabled = true,
    this.guestsEnabled = true,
    this.coBroadcastEnabled = false,
    this.guestLayout = LiveGuestLayout.solo,
  });

  final bool commentsEnabled;
  final bool giftsEnabled;
  final bool fortuneRequestsEnabled;
  final bool pkEnabled;
  final bool guestsEnabled;
  final bool coBroadcastEnabled;
  final LiveGuestLayout guestLayout;

  LiveBroadcastSettings copyWith({
    bool? commentsEnabled,
    bool? giftsEnabled,
    bool? fortuneRequestsEnabled,
    bool? pkEnabled,
    bool? guestsEnabled,
    bool? coBroadcastEnabled,
    LiveGuestLayout? guestLayout,
  }) {
    return LiveBroadcastSettings(
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      giftsEnabled: giftsEnabled ?? this.giftsEnabled,
      fortuneRequestsEnabled:
          fortuneRequestsEnabled ?? this.fortuneRequestsEnabled,
      pkEnabled: pkEnabled ?? this.pkEnabled,
      guestsEnabled: guestsEnabled ?? this.guestsEnabled,
      coBroadcastEnabled: coBroadcastEnabled ?? this.coBroadcastEnabled,
      guestLayout: guestLayout ?? this.guestLayout,
    );
  }
}

class LiveBroadcastSettingsNotifier extends Notifier<LiveBroadcastSettings> {
  @override
  LiveBroadcastSettings build() => const LiveBroadcastSettings();

  void toggleComments(bool value) =>
      state = state.copyWith(commentsEnabled: value);

  void toggleGifts(bool value) => state = state.copyWith(giftsEnabled: value);

  void toggleFortuneRequests(bool value) =>
      state = state.copyWith(fortuneRequestsEnabled: value);

  void togglePk(bool value) => state = state.copyWith(pkEnabled: value);

  void toggleGuests(bool value) =>
      state = state.copyWith(guestsEnabled: value);

  void toggleCoBroadcast(bool value) =>
      state = state.copyWith(coBroadcastEnabled: value);

  void setGuestLayout(LiveGuestLayout layout) =>
      state = state.copyWith(guestLayout: layout);
}

final liveBroadcastSettingsProvider =
    NotifierProvider<LiveBroadcastSettingsNotifier, LiveBroadcastSettings>(
  LiveBroadcastSettingsNotifier.new,
);
