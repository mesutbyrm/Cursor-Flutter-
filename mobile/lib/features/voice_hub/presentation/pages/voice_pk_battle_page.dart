import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../widgets/premium_2026/voice_live_chat_dock.dart';

/// PK savaş ekranı — 1v1 skor, destekçiler, canlı sohbet.
class VoicePkBattlePage extends ConsumerStatefulWidget {
  const VoicePkBattlePage({
    super.key,
    required this.room,
    this.leftUser,
    this.rightUser,
  });

  final VoiceRoomEntity room;
  final ChatRoomPresence? leftUser;
  final ChatRoomPresence? rightUser;

  @override
  ConsumerState<VoicePkBattlePage> createState() => _VoicePkBattlePageState();
}

class _VoicePkBattlePageState extends ConsumerState<VoicePkBattlePage> {
  final _messageCtrl = TextEditingController();
  Timer? _timer;
  var _secondsLeft = 272;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _secondsLeft <= 0) return;
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageCtrl.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(voiceRoomLiveProvider(widget.room));
    final presence = live.presence;
    final left = widget.leftUser ?? _pickSide(presence, 0);
    final right = widget.rightUser ?? _pickSide(presence, 1);

    final leftScore = _scoreFor(left, 12500);
    final rightScore = _scoreFor(right, 8700);
    final totalL = leftScore + 4200;
    final totalR = rightScore + 3800;

    return Scaffold(
      backgroundColor: VoiceRoomTokens.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VoiceCosmicBackground(),
          SafeArea(
            child: Column(
              children: [
                _PkTopBar(
                  title: 'PK Savaşı',
                  time: _timeLabel,
                  onClose: () => context.pop(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PkSidePanel(
                              user: left,
                              score: leftScore,
                              total: totalL,
                              gradient: const [
                                Color(0xFF1565C0),
                                Color(0xFF0D1B3E),
                              ],
                              ringColor: VoiceRoomTokens.gold,
                              alignEnd: false,
                            ),
                          ),
                          Expanded(
                            child: _PkSidePanel(
                              user: right,
                              score: rightScore,
                              total: totalR,
                              gradient: const [
                                Color(0xFFC62828),
                                Color(0xFF2A0A12),
                              ],
                              ringColor: VoiceRoomTokens.neonPink,
                              alignEnd: true,
                            ),
                          ),
                        ],
                      ),
                      Center(child: _VsBadge()),
                    ],
                  ),
                ),
                _SupportersRow(
                  leftTotal: totalL,
                  rightTotal: totalR,
                  supporters: presence.take(8).toList(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: VoiceLiveChatDock(
                    messages: live.messages,
                    controller: _messageCtrl,
                    maxHeight: 100,
                    onSend: () {
                      final t = _messageCtrl.text;
                      _messageCtrl.clear();
                      ref
                          .read(voiceRoomLiveProvider(widget.room).notifier)
                          .sendMessage(t);
                    },
                    onGift: () {},
                  ),
                ),
                _PkBottomActions(
                  onGift: () {},
                  onMenu: () => context.pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ChatRoomPresence? _pickSide(List<ChatRoomPresence> list, int index) {
    if (list.length > index) return list[index];
    if (index == 0 && widget.room.ownerName != null) {
      return ChatRoomPresence(
        id: widget.room.ownerId ?? 'host',
        name: widget.room.ownerName!,
        image: widget.room.ownerAvatarUrl,
        chatRole: 'owner',
      );
    }
    return null;
  }

  int _scoreFor(ChatRoomPresence? u, int fallback) {
    if (u == null) return fallback;
    return fallback + (u.id.hashCode.abs() % 3000);
  }
}

class _PkTopBar extends StatelessWidget {
  const _PkTopBar({
    required this.title,
    required this.time,
    required this.onClose,
  });

  final String title;
  final String time;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [VoiceRoomTokens.gold, Color(0xFFFFE082)],
                  ).createShader(b),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: VoiceRoomTokens.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _VsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFF6F00)],
        ),
        boxShadow: VoiceRoomTokens.goldGlow(blur: 28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: const Text(
        'VS',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
        ),
      ),
    );
  }
}

class _PkSidePanel extends StatelessWidget {
  const _PkSidePanel({
    required this.user,
    required this.score,
    required this.total,
    required this.gradient,
    required this.ringColor,
    required this.alignEnd,
  });

  final ChatRoomPresence? user;
  final int score;
  final int total;
  final List<Color> gradient;
  final Color ringColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? '—';
    final img = user?.image;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          end: Alignment.center,
          colors: gradient,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 3),
                boxShadow: VoiceRoomTokens.neonGlow(ringColor, blur: 16),
              ),
              child: ClipOval(
                child: img != null && img.isNotEmpty
                    ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                    : ColoredBox(
                        color: Colors.white12,
                        child: Icon(Icons.person, size: 48, color: ringColor),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            Text(
              _fmt(score),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: VoiceRoomTokens.gold,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: gradient.first.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text('Takip Et', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _SupportersRow extends StatelessWidget {
  const _SupportersRow({
    required this.leftTotal,
    required this.rightTotal,
    required this.supporters,
  });

  final int leftTotal;
  final int rightTotal;
  final List<ChatRoomPresence> supporters;

  @override
  Widget build(BuildContext context) {
    final half = (supporters.length / 2).ceil();
    final left = supporters.take(half).toList();
    final right = supporters.skip(half).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: VoiceRoomTokens.glassCard(radius: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Toplam ${_PkSidePanel._fmt(leftTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                    const Text(
                      '💪 Destekleyenler',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    Expanded(
                      child: Text(
                        '${_PkSidePanel._fmt(rightTotal)} Toplam',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _AvatarRow(users: left, color: Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _AvatarRow(users: right, color: Colors.red)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.users, required this.color});

  final List<ChatRoomPresence> users;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < 4; i++)
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.3),
            backgroundImage: i < users.length &&
                    users[i].image != null &&
                    users[i].image!.isNotEmpty
                ? CachedNetworkImageProvider(users[i].image!)
                : null,
            child: i >= users.length
                ? Icon(Icons.person, size: 16, color: color.withValues(alpha: 0.8))
                : null,
          ),
      ],
    );
  }
}

class _PkBottomActions extends StatelessWidget {
  const _PkBottomActions({required this.onGift, required this.onMenu});

  final VoidCallback onGift;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottom + 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Yorum ekle…',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleBtn(
            icon: Icons.card_giftcard_rounded,
            gradient: VoiceRoomTokens.followGradient,
            onTap: onGift,
          ),
          const SizedBox(width: 8),
          _CircleBtn(
            icon: Icons.menu_rounded,
            color: Colors.white24,
            onTap: onMenu,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    this.gradient,
    this.color,
    required this.onTap,
  });

  final IconData icon;
  final Gradient? gradient;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            color: gradient == null
                ? color ?? Colors.white.withValues(alpha: 0.1)
                : null,
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
