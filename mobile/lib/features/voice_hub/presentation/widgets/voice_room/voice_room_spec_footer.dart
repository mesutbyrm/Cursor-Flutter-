import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_room_bottom_action_bar.dart';
import 'voice_room_join_toast_stack.dart';
import 'voice_room_mention_text_field.dart';

/// Alt bar — mesaj satırı + Faz 6 aksiyon menüsü.
class VoiceRoomSpecFooter extends StatelessWidget {
  const VoiceRoomSpecFooter({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onToggleAudioOutput,
    required this.headphonesOn,
    required this.onMicToggle,
    required this.micOn,
    required this.micEnabled,
    required this.onSettings,
    required this.onGift,
    required this.onInvite,
    this.presence = const [],
    this.selfUserId,
    this.events = const [],
    this.messages = const [],
    this.onEmojiTap,
    this.onChanged,
    this.joinNotificationsEnabled = true,
    this.onMusicRequest,
    this.showMusicRequest = false,
    this.onSpeakRequest,
    this.speakRequestPending = false,
    this.showSpeakRequest = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onToggleAudioOutput;
  final bool headphonesOn;
  final VoidCallback onMicToggle;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onSettings;
  final VoidCallback onGift;
  final VoidCallback onInvite;
  final List<ChatRoomPresence> presence;
  final String? selfUserId;
  final List<VoiceRoomRealtimeEvent> events;
  final List<ChatRoomMessage> messages;
  final VoidCallback? onEmojiTap;
  final ValueChanged<String>? onChanged;
  final bool joinNotificationsEnabled;
  final VoidCallback? onMusicRequest;
  final bool showMusicRequest;
  final VoidCallback? onSpeakRequest;
  final bool speakRequestPending;
  final bool showSpeakRequest;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onEmojiTap,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: VoiceRoomMentionTextField(
                    controller: controller,
                    focusNode: focusNode,
                    presence: presence,
                    excludeUserId: selfUserId,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSend(),
                    hintText: 'Mesajınızı yazın...',
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: VoiceRoomTokens.neonPurple,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showMusicRequest && onMusicRequest != null) ...[
                  const SizedBox(width: 6),
                  Material(
                    color: VoiceRoomTokens.gold.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onMusicRequest,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Colors.black87,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Material(
                  color: VoiceRoomTokens.neonPurple,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSend,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            VoiceRoomJoinToastStack(
              events: events,
              messages: messages,
              enabled: joinNotificationsEnabled,
            ),
            VoiceRoomBottomActionBar(
              headphonesOn: headphonesOn,
              onToggleAudioOutput: onToggleAudioOutput,
              onSettings: onSettings,
              micOn: micOn,
              micEnabled: micEnabled,
              onMicToggle: onMicToggle,
              onGift: onGift,
              onInvite: onInvite,
              onSpeakRequest: onSpeakRequest,
              speakRequestPending: speakRequestPending,
              showSpeakRequest: showSpeakRequest,
            ),
          ],
        ),
      ),
    );
  }
}
