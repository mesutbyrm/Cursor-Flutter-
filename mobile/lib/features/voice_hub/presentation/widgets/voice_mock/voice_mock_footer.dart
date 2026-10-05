import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_room_presence.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../pk_room/pk_room_controller.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_chat_flood_guard.dart';
import '../voice_room/voice_room_join_toast_stack.dart';
import '../voice_room/voice_room_mention_text_field.dart';

/// Alt bölüm — mesaj satırı (emoji · alan · gönder) + 5'li dock
/// (Temizle/Ses · Mikrofon · Konuş · Hediye · Oda Modu).
class VoiceMockFooter extends ConsumerWidget {
  const VoiceMockFooter({
    super.key,
    required this.liveRoomKey,
    required this.room,
    required this.userId,
    required this.controller,
    required this.focusNode,
    required this.micOn,
    required this.micEnabled,
    required this.onSend,
    required this.onToggleAudioOutput,
    required this.onMicToggle,
    required this.onGift,
    required this.onEmojiTap,
    required this.onChanged,
    required this.onRoomMode,
    required this.canClearChat,
    required this.onClearChat,
    this.showInput = true,
    this.showDock = true,
    this.pkChatOpen = false,
  });

  final String liveRoomKey;
  final VoiceRoomEntity room;
  final String? userId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onSend;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onMicToggle;
  final VoidCallback onGift;
  final VoidCallback onEmojiTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onRoomMode;

  /// Yetkili (sahip/moderatör/admin) ise süpürge sohbeti temizler.
  final bool canClearChat;
  final VoidCallback onClearChat;

  /// Mesaj satırı klavyeye sabitlenir; dock klavyenin ARKASINDA sabit kalır.
  final bool showInput;
  final bool showDock;
  final bool pkChatOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(voiceRoomUiProvider.select(voiceRoomUiFooterSlice));
    final sendEnabled = !ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select(
        (s) => VoiceRoomChatFloodGuard.isFloodMessage(s.error),
      ),
    );
    final pkOverlay = ref.watch(
      pkRoomControllerProvider(liveRoomKey).select((s) => s.overlayVisible),
    );
    final hideInput = pkOverlay && !pkChatOpen;
    final presence = ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select((s) => s.presence),
    );
    final toast = Consumer(
      builder: (context, ref, _) {
        ref.watch(
          voiceRoomLiveProvider(liveRoomKey).select(
            (s) => voiceRoomJoinToastSignature(
              messages: s.messages,
              events: s.realtimeEvents,
            ),
          ),
        );
        final live = ref.read(voiceRoomLiveProvider(liveRoomKey));
        return VoiceRoomJoinToastStack(
          events: live.realtimeEvents,
          messages: live.messages,
          enabled: ui.chatNotificationSoundEnabled,
        );
      },
    );
    return VoiceMockFooterView(
      presence: List<ChatRoomPresence>.of(presence),
      toast: toast,
      headphonesOn: ui.headphonesOn,
      sendEnabled: sendEnabled,
      hideInput: hideInput,
      userId: userId,
      controller: controller,
      focusNode: focusNode,
      micOn: micOn,
      micEnabled: micEnabled,
      onSend: onSend,
      onToggleAudioOutput: onToggleAudioOutput,
      onMicToggle: onMicToggle,
      onGift: onGift,
      onEmojiTap: onEmojiTap,
      onChanged: onChanged,
      onRoomMode: onRoomMode,
      canClearChat: canClearChat,
      onClearChat: onClearChat,
      showInput: showInput,
      showDock: showDock,
    );
  }
}

/// Saf görünüm — sağlayıcı bağımsız (test/render için).
class VoiceMockFooterView extends StatelessWidget {
  const VoiceMockFooterView({
    super.key,
    required this.presence,
    required this.toast,
    required this.headphonesOn,
    required this.sendEnabled,
    required this.hideInput,
    required this.userId,
    required this.controller,
    required this.focusNode,
    required this.micOn,
    required this.micEnabled,
    required this.onSend,
    required this.onToggleAudioOutput,
    required this.onMicToggle,
    required this.onGift,
    required this.onEmojiTap,
    required this.onChanged,
    required this.onRoomMode,
    this.canClearChat = false,
    this.onClearChat,
    this.showInput = true,
    this.showDock = true,
  });

  final List<ChatRoomPresence> presence;
  final Widget toast;
  final bool headphonesOn;
  final bool sendEnabled;
  final bool hideInput;
  final String? userId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onSend;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onMicToggle;
  final VoidCallback onGift;
  final VoidCallback onEmojiTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onRoomMode;
  final bool canClearChat;
  final VoidCallback? onClearChat;
  final bool showInput;
  final bool showDock;

  /// Dock yüksekliği (sabit): klavye açılınca mesaj satırını doğru kaldırmak için.
  static const dockBodyHeight = 64.0;
  static const _dockPadTop = 6.0;
  static double dockHeight(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return _dockPadTop + dockBodyHeight + (bottom > 0 ? bottom : 8);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final inputRow = Row(
      children: [
        _RoundIcon(
          onTap: onEmojiTap,
          child: const Icon(
            Icons.sentiment_satisfied_alt_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: VoiceRoomMentionTextField(
            controller: controller,
            focusNode: focusNode,
            presence: presence,
            excludeUserId: userId,
            onChanged: onChanged,
            onSubmitted: sendEnabled ? (_) => onSend() : null,
            hintText: 'Mesaj yaz... (istek)',
            decoration: _decoration(),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: sendEnabled ? onSend : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.send_rounded,
              size: 30,
              color: Colors.white.withValues(alpha: sendEnabled ? 1 : 0.4),
            ),
          ),
        ),
      ],
    );

    // 5 eşit hücre: ortadaki hücre «Konuş» tam ortada durur.
    Widget cell(Widget child) => Expanded(child: Center(child: child));
    final dock = Container(
      height: dockBodyHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          cell(
            canClearChat
                ? _DockBtn(
                    label: 'Temizle',
                    onTap: onClearChat ?? () {},
                    color: const Color(0xFF38BDF8),
                    icon: Icons.cleaning_services_rounded,
                  )
                : _DockBtn(
                    label: headphonesOn ? 'Ses açık' : 'Ses kapalı',
                    onTap: onToggleAudioOutput,
                    color: headphonesOn
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    icon: headphonesOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                  ),
          ),
          cell(
            _DockBtn(
              label: micOn ? 'Mikrofon' : 'Kapalı',
              onTap: onMicToggle,
              color: micOn ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              strike: !micOn,
            ),
          ),
          cell(
            _TalkBtn(active: micOn, enabled: micEnabled, onTap: onMicToggle),
          ),
          cell(
            _DockBtn(
              label: 'Hediye',
              onTap: onGift,
              color: VoiceRoomTokens.gold,
              icon: Icons.card_giftcard_rounded,
            ),
          ),
          cell(
            _DockBtn(
              label: 'Oda Modu',
              onTap: onRoomMode,
              color: Colors.white,
              icon: Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          showInput ? 6 : _dockPadTop,
          10,
          showDock ? (bottomInset > 0 ? bottomInset : 8) : 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showInput && !hideInput) inputRow,
            if (showInput) toast,
            if (showInput && showDock) const SizedBox(height: 8),
            if (showDock) dock,
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      hintText: 'Mesaj yaz... (istek)',
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.5),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(color: VoiceRoomTokens.neonPurple),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: child,
      ),
    );
  }
}

class _DockBtn extends StatelessWidget {
  const _DockBtn({
    required this.label,
    required this.onTap,
    required this.color,
    required this.icon,
    this.strike = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 21, color: color),
                  if (strike)
                    Transform.rotate(
                      angle: -0.8,
                      child: Container(
                        width: 28,
                        height: 2.4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TalkBtn extends StatelessWidget {
  const _TalkBtn({
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF4D6D), Color(0xFFE11D48)],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2D55)
                            .withValues(alpha: active ? 0.75 : 0.45),
                        blurRadius: active ? 18 : 10,
                        spreadRadius: active ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic_rounded, size: 26, color: Colors.white),
                      Text(
                        active ? 'Konuşuyor' : 'Konuş',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
