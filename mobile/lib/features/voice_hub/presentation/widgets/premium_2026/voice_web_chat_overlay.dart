import 'package:flutter/material.dart';

import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_chat_message_filters.dart';
import '../chat/chat_message_widgets.dart';

/// Web tarzı şeffaf sohbet — arka plan üzerinde yüzen mesajlar.
class VoiceWebChatOverlay extends StatelessWidget {
  const VoiceWebChatOverlay({
    super.key,
    required this.messages,
    this.onUserTap,
    this.hideOfficialJoinInChat = false,
    this.maxHeight = 220,
    this.embedded = false,
    this.welcomeMarquee,
    this.roomName,
    this.pinnedAnnouncement,
  });

  final List<ChatRoomMessage> messages;
  final void Function(String userId, String name)? onUserTap;
  final bool hideOfficialJoinInChat;
  final double maxHeight;
  final bool embedded;
  final String? welcomeMarquee;
  final String? roomName;
  final String? pinnedAnnouncement;

  @override
  Widget build(BuildContext context) {
    final visible = messages.where((m) {
      if (!VoiceChatMessageFilters.shouldShow(m)) return false;
      if (hideOfficialJoinInChat &&
          m.kind == ChatMessageKind.systemJoin &&
          VoiceOfficialJoin.isOfficialEntrance(m.content)) {
        return false;
      }
      return m.kind == ChatMessageKind.text || m.kind == ChatMessageKind.gift;
    }).toList();
    final slice = visible.length > 40
        ? visible.sublist(visible.length - 40)
        : visible;

    if (slice.isEmpty) {
      final marquee = welcomeMarquee?.trim();
      if (marquee != null && marquee.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sohbet odasına hoş geldiniz — mesajınızı yazın',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 6),
              _WelcomeEntranceMarquee(
                message: VoiceOfficialJoin.formatEntranceBanner(
                  marquee,
                  roomName: roomName,
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'Sohbet odasına hoş geldiniz — mesajınızı yazın',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.55),
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6),
            ],
          ),
        ),
      );
    }

    final pinned = pinnedAnnouncement?.trim();
    final hasPinned = pinned != null && pinned.isNotEmpty;

    final list = ListView.builder(
      reverse: true,
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: slice.length + (hasPinned ? 1 : 0),
      itemBuilder: (context, i) {
        if (hasPinned && i == 0) {
          return _PinnedAnnouncementBar(text: pinned);
        }
        final msgIndex = hasPinned ? i - 1 : i;
        final msg = slice[slice.length - 1 - msgIndex];
        if (_isMusicSystemLine(msg.content)) {
          return MusicSystemChatLine(
            key: ValueKey(msg.id),
            text: msg.content,
          );
        }
        return ChatMessageWidget(
          key: ValueKey(msg.id),
          message: msg,
          onUserTap: onUserTap,
        );
      },
    );

    if (embedded) {
      return RepaintBoundary(
        child: SizedBox(
          height: maxHeight,
          width: double.infinity,
          child: list,
        ),
      );
    }

    return SizedBox(
      height: maxHeight,
      child: Stack(
        children: [
          list,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 24,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      VoiceRoomTokens.bgDeep.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isMusicSystemLine(String content) {
  final c = content.trim();
  return c.startsWith('🎵') ||
      c.startsWith('🎁') ||
      c.startsWith('📀') ||
      c.startsWith('🔢') ||
      c.startsWith('⏭️') ||
      c.startsWith('🗑️') ||
      c.startsWith('🧹');
}

/// !duyuru — sohbet listesinin üstünde sabit duyuru şeridi.
class _PinnedAnnouncementBar extends StatelessWidget {
  const _PinnedAnnouncementBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF0080).withValues(alpha: 0.35),
            const Color(0xFF7B2FF7).withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF4FD8).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Web giriş çubuğu — yalnızca metin ve gönder (mikrofon alt barda).
class VoiceWebChatInputBar extends StatelessWidget {
  const VoiceWebChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.sending = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: TextStyle(
                      color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: VoiceRoomTokens.neonPurple,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: sending ? null : onSend,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

/// Hoş geldin alanında sağdan sola kayan giriş şeridi.
class _WelcomeEntranceMarquee extends StatefulWidget {
  const _WelcomeEntranceMarquee({required this.message});

  final String message;

  @override
  State<_WelcomeEntranceMarquee> createState() => _WelcomeEntranceMarqueeState();
}

class _WelcomeEntranceMarqueeState extends State<_WelcomeEntranceMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.message.trim();
    if (line.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.35)),
        ),
        child: SizedBox(
          height: 28,
          child: AnimatedBuilder(
            animation: _scroll,
            builder: (context, _) {
              return OverflowBox(
                maxWidth: double.infinity,
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(-_scroll.value * 140, 0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: VoiceRoomTokens.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Text(
                        line,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: VoiceRoomTokens.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
