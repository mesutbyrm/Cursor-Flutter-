import 'package:flutter/material.dart';

import '../voice_room/voice_room_bottom_action_bar.dart';

/// Basic oda alt menüsü — Faz 6 layout ([VoiceRoomBottomActionBar]).
class VoiceLiveActionBar2026 extends StatelessWidget {
  const VoiceLiveActionBar2026({
    super.key,
    required this.micOn,
    required this.micEnabled,
    required this.onMic,
    required this.onGift,
    required this.onSettings,
    required this.onToggleAudioOutput,
    required this.headphonesOn,
    required this.onInvite,
  });

  final bool micOn;
  final bool micEnabled;
  final bool headphonesOn;
  final VoidCallback onMic;
  final VoidCallback onGift;
  final VoidCallback onSettings;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return VoiceRoomBottomActionBar(
      headphonesOn: headphonesOn,
      onToggleAudioOutput: onToggleAudioOutput,
      onSettings: onSettings,
      micOn: micOn,
      micEnabled: micEnabled,
      onMicToggle: onMic,
      onGift: onGift,
      onInvite: onInvite,
    );
  }
}
