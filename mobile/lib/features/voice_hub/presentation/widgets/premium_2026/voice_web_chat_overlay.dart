import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_chat_message_filters.dart';
import '../../../../../core/auth/voice_staff_rank.dart';

/// Web tarzı şeffaf sohbet — arka plan üzerinde yüzen mesajlar.
class VoiceWebChatOverlay extends StatelessWidget {
  const VoiceWebChatOverlay({
    super.key,
    required this.messages,
    this.onUserTap,
    this.hideOfficialJoinInChat = false,
    this.maxHeight = 220,
    this.embedded = false,
  });

  final List<ChatRoomMessage> messages;
  final void Function(String userId, String name)? onUserTap;
  final bool hideOfficialJoinInChat;
  final double maxHeight;
  final bool embedded;

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

    final list = ListView.builder(
      reverse: true,
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: slice.length,
      itemBuilder: (context, i) {
        final msg = slice[slice.length - 1 - i];
        if (_isMusicSystemLine(msg.content)) {
          return _AnimatedMusicChatLine(
            key: ValueKey(msg.id),
            text: msg.content,
          );
        }
        return _WebChatLine(message: msg, onUserTap: onUserTap);
      },
    );

    if (embedded) {
      return RepaintBoundary(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
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

class _AnimatedMusicChatLine extends StatefulWidget {
  const _AnimatedMusicChatLine({super.key, required this.text});

  final String text;

  @override
  State<_AnimatedMusicChatLine> createState() => _AnimatedMusicChatLineState();
}

class _AnimatedMusicChatLineState extends State<_AnimatedMusicChatLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB388FF),
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebChatLine extends StatelessWidget {
  const _WebChatLine({required this.message, this.onUserTap});

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      final icon = _joinIcon(message.content);
      final color = _joinColor(message.content);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.kind == ChatMessageKind.gift) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          message.content,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: VoiceRoomTokens.gold,
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
      );
    }

    final user = message.user;
    final name = user?.displayWithPrefix ?? 'Kullanıcı';
    final tier = VipTier.fromMembership(user?.membership);
    final vip = user?.isBroadcaster == true || tier.index >= VipTier.gold.index;

    final rank = VoiceStaffRankParser.resolve(
      username: user?.nickname ?? user?.name,
      chatRole: user?.chatRole,
    );
    final styled = _isStyledName(user, vip, rank);
    final nameColor = _usernameColor(user, vip, rank);
    final showIstek = _isIstekLine(message.content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: user != null ? () => onUserTap?.call(user.id, name) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: styled
                  ? nameColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _StyledUsername(
                          name: '$name ',
                          color: nameColor,
                          styled: styled,
                        ),
                      ),
                      TextSpan(text: message.content),
                    ],
                  ),
                ),
              ),
              if (showIstek)
                Container(
                  margin: const EdgeInsets.only(left: 6, top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'İSTEK',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isIstekLine(String content) {
  final c = content.trim().toLowerCase();
  return c.startsWith('!istek') || c.contains('şarkı isteği');
}

bool _isStyledName(
  ChatRoomUserRef? user,
  bool vip,
  VoiceStaffRank rank,
) {
  if (vip) return true;
  if (user?.chatRole == 'owner' || user?.chatRole == 'founder') return true;
  return VoiceStaffRankParser.powerLevel(rank) >=
      VoiceStaffRankParser.powerLevel(VoiceStaffRank.op);
}

Color _usernameColor(ChatRoomUserRef? user, bool vip, VoiceStaffRank rank) {
  if (user?.chatRole == 'owner' || user?.chatRole == 'founder') {
    return VoiceRoomTokens.gold;
  }
  if (VoiceStaffRankParser.powerLevel(rank) >=
      VoiceStaffRankParser.powerLevel(VoiceStaffRank.admin)) {
    return VoiceRoomTokens.gold;
  }
  if (VoiceStaffRankParser.canModerate(rank)) return VoiceRoomTokens.neonPurple;
  if (user?.chatRole == 'dj') return VoiceRoomTokens.neonPink;
  if (user?.isBroadcaster == true) return VoiceRoomTokens.neonBlue;
  if (vip) return VoiceRoomTokens.gold;
  return const Color(0xFF4ADE80);
}

class _StyledUsername extends StatelessWidget {
  const _StyledUsername({
    required this.name,
    required this.color,
    required this.styled,
  });

  final String name;
  final Color color;
  final bool styled;

  @override
  Widget build(BuildContext context) {
    if (!styled) {
      return Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: color,
        ),
      );
    }
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          color,
          color.withValues(alpha: 0.75),
          VoiceRoomTokens.neonPink.withValues(alpha: 0.9),
        ],
      ).createShader(bounds),
      child: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

IconData _joinIcon(String content) {
  final u = content.toUpperCase();
  if (u.contains('ADMIN') || u.contains('KURUCU') || u.contains('FOUNDER')) {
    return Icons.workspace_premium_rounded;
  }
  if (u.contains('DJ')) return Icons.auto_awesome_rounded;
  if (u.contains('GOLD') || u.contains('VIP')) {
    return Icons.hexagon_rounded;
  }
  return Icons.person_add_alt_1_rounded;
}

Color _joinColor(String content) {
  final u = content.toUpperCase();
  if (u.contains('ADMIN') || u.contains('GOLD') || u.contains('VIP')) {
    return VoiceRoomTokens.gold;
  }
  if (u.contains('DJ')) return VoiceRoomTokens.neonPink;
  return VoiceRoomTokens.neonBlue;
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
