import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoiceEffectPreset {
  normal,
  studio,
  robot,
  megaphone,
  angry,
  deep,
  space,
}

class VoiceRoomUiState {
  const VoiceRoomUiState({
    this.headphonesOn = true,
    this.requestSpeakPending = false,
    this.speakRequestBlocked = false,
    this.speakBlockReason,
    this.effect = VoiceEffectPreset.normal,
    this.effectVolume = 0.8,
    this.listenerMessagesEnabled = true,
    this.giftAnimationsEnabled = true,
    this.backgroundMusicEnabled = true,
    this.chatNotificationSoundEnabled = true,
    this.autoOpenMic = false,
  });

  final bool headphonesOn;
  final bool requestSpeakPending;
  final bool speakRequestBlocked;
  final String? speakBlockReason;
  final VoiceEffectPreset effect;
  final double effectVolume;
  final bool listenerMessagesEnabled;
  final bool giftAnimationsEnabled;
  final bool backgroundMusicEnabled;
  final bool chatNotificationSoundEnabled;
  final bool autoOpenMic;

  /// Hoparlör kapalı veya müzik sessize alınmış.
  bool get effectiveMusicMuted =>
      !backgroundMusicEnabled || !headphonesOn;

  /// RTC, hediye SFX ve müzik çıkışı için hoparlör açık mı.
  bool get roomOutputEnabled => headphonesOn;

  VoiceRoomUiState copyWith({
    bool? headphonesOn,
    bool? requestSpeakPending,
    bool? speakRequestBlocked,
    String? speakBlockReason,
    bool clearSpeakBlockReason = false,
    VoiceEffectPreset? effect,
    double? effectVolume,
    bool? listenerMessagesEnabled,
    bool? giftAnimationsEnabled,
    bool? backgroundMusicEnabled,
    bool? chatNotificationSoundEnabled,
    bool? autoOpenMic,
  }) {
    return VoiceRoomUiState(
      headphonesOn: headphonesOn ?? this.headphonesOn,
      requestSpeakPending: requestSpeakPending ?? this.requestSpeakPending,
      speakRequestBlocked: speakRequestBlocked ?? this.speakRequestBlocked,
      speakBlockReason: clearSpeakBlockReason
          ? null
          : (speakBlockReason ?? this.speakBlockReason),
      effect: effect ?? this.effect,
      effectVolume: effectVolume ?? this.effectVolume,
      listenerMessagesEnabled:
          listenerMessagesEnabled ?? this.listenerMessagesEnabled,
      giftAnimationsEnabled:
          giftAnimationsEnabled ?? this.giftAnimationsEnabled,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      chatNotificationSoundEnabled: chatNotificationSoundEnabled ??
          this.chatNotificationSoundEnabled,
      autoOpenMic: autoOpenMic ?? this.autoOpenMic,
    );
  }
}

class VoiceRoomUiNotifier extends Notifier<VoiceRoomUiState> {
  @override
  VoiceRoomUiState build() => const VoiceRoomUiState();

  void toggleHeadphones() =>
      state = state.copyWith(headphonesOn: !state.headphonesOn);

  void setEffect(VoiceEffectPreset e) => state = state.copyWith(effect: e);

  void setEffectVolume(double v) =>
      state = state.copyWith(effectVolume: v.clamp(0, 1));

  void toggleRequestSpeak() =>
      state = state.copyWith(requestSpeakPending: !state.requestSpeakPending);

  void setRequestSpeakPending(bool pending) =>
      state = state.copyWith(requestSpeakPending: pending);

  void setSpeakRequestBlocked({
    required bool blocked,
    String? reason,
  }) =>
      state = state.copyWith(
        speakRequestBlocked: blocked,
        speakBlockReason: reason,
        clearSpeakBlockReason: reason == null && !blocked,
        requestSpeakPending: blocked ? false : state.requestSpeakPending,
      );

  void toggleListenerMessages() => state = state.copyWith(
        listenerMessagesEnabled: !state.listenerMessagesEnabled,
      );

  void toggleGiftAnimations() => state = state.copyWith(
        giftAnimationsEnabled: !state.giftAnimationsEnabled,
      );

  void toggleBackgroundMusic() => state = state.copyWith(
        backgroundMusicEnabled: !state.backgroundMusicEnabled,
      );

  void toggleChatNotificationSound() => state = state.copyWith(
        chatNotificationSoundEnabled: !state.chatNotificationSoundEnabled,
      );

  void toggleAutoOpenMic() =>
      state = state.copyWith(autoOpenMic: !state.autoOpenMic);

  /// Şarkı isteği / sunucu çalma — hoparlör ve müzik çıkışını aç.
  void ensureMusicAudible() {
    if (state.headphonesOn && state.backgroundMusicEnabled) return;
    state = state.copyWith(
      headphonesOn: true,
      backgroundMusicEnabled: true,
    );
  }
}

final voiceRoomUiProvider =
    NotifierProvider<VoiceRoomUiNotifier, VoiceRoomUiState>(
  VoiceRoomUiNotifier.new,
);

/// Sesli oda RTC ekranı ön plandayken global mini player gösterilmez.
final voiceRoomRtcForegroundProvider = StateProvider<bool>((ref) => false);

/// [VoiceRoomRtcPage] mount — sayfa dispose olunca [voiceRoomRtcForegroundProvider] sıfırlanır.
final voiceRoomForegroundLifecycleProvider =
    Provider.autoDispose.family<void, String>((ref, roomKey) {
  ref.read(voiceRoomRtcForegroundProvider.notifier).state = true;
  ref.onDispose(() {
    ref.read(voiceRoomRtcForegroundProvider.notifier).state = false;
  });
});
