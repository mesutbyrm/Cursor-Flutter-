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
    this.effect = VoiceEffectPreset.normal,
    this.effectVolume = 0.8,
    this.listenerMessagesEnabled = true,
    this.giftAnimationsEnabled = true,
    this.backgroundMusicEnabled = false,
    this.autoOpenMic = false,
  });

  final bool headphonesOn;
  final bool requestSpeakPending;
  final VoiceEffectPreset effect;
  final double effectVolume;
  final bool listenerMessagesEnabled;
  final bool giftAnimationsEnabled;
  final bool backgroundMusicEnabled;
  final bool autoOpenMic;

  VoiceRoomUiState copyWith({
    bool? headphonesOn,
    bool? requestSpeakPending,
    VoiceEffectPreset? effect,
    double? effectVolume,
    bool? listenerMessagesEnabled,
    bool? giftAnimationsEnabled,
    bool? backgroundMusicEnabled,
    bool? autoOpenMic,
  }) {
    return VoiceRoomUiState(
      headphonesOn: headphonesOn ?? this.headphonesOn,
      requestSpeakPending: requestSpeakPending ?? this.requestSpeakPending,
      effect: effect ?? this.effect,
      effectVolume: effectVolume ?? this.effectVolume,
      listenerMessagesEnabled:
          listenerMessagesEnabled ?? this.listenerMessagesEnabled,
      giftAnimationsEnabled:
          giftAnimationsEnabled ?? this.giftAnimationsEnabled,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
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

  void toggleListenerMessages() => state = state.copyWith(
        listenerMessagesEnabled: !state.listenerMessagesEnabled,
      );

  void toggleGiftAnimations() => state = state.copyWith(
        giftAnimationsEnabled: !state.giftAnimationsEnabled,
      );

  void toggleBackgroundMusic() => state = state.copyWith(
        backgroundMusicEnabled: !state.backgroundMusicEnabled,
      );

  void toggleAutoOpenMic() =>
      state = state.copyWith(autoOpenMic: !state.autoOpenMic);
}

final voiceRoomUiProvider =
    NotifierProvider<VoiceRoomUiNotifier, VoiceRoomUiState>(
  VoiceRoomUiNotifier.new,
);
