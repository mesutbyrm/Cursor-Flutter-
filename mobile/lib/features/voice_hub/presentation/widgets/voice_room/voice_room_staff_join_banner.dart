import 'dart:async';

import 'package:flutter/material.dart';

import 'package:canlifal_social/core/auth/voice_staff_rank.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';

/// Üst şerit — yetkili/VIP girişleri herkese sağdan sola gösterilir.
class VoiceRoomStaffJoinBanner extends StatefulWidget {
  const VoiceRoomStaffJoinBanner({
    super.key,
    required this.events,
    required this.messages,
    this.enterBanner,
  });

  final List<VoiceRoomRealtimeEvent> events;
  final List<ChatRoomMessage> messages;
  final String? enterBanner;

  @override
  State<VoiceRoomStaffJoinBanner> createState() =>
      _VoiceRoomStaffJoinBannerState();
}

class _StaffJoinLine {
  _StaffJoinLine({
    required this.name,
    required this.roleLabel,
    required this.roleColor,
    required this.icon,
  });

  final String name;
  final String roleLabel;
  final Color roleColor;
  final IconData icon;
}

class _VoiceRoomStaffJoinBannerState extends State<VoiceRoomStaffJoinBanner>
    with SingleTickerProviderStateMixin {
  final _queue = <_StaffJoinLine>[];
  _StaffJoinLine? _active;
  AnimationController? _ctrl;
  Animation<Offset>? _slide;
  Animation<double>? _fade;
  String? _lastBanner;
  int _lastEventCount = 0;
  int _lastJoinMsgCount = 0;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomStaffJoinBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _collectNewEntries();
  }

  @override
  void initState() {
    super.initState();
    _collectNewEntries();
  }

  void _collectNewEntries() {
    final banner = widget.enterBanner?.trim();
    if (banner != null &&
        banner.isNotEmpty &&
        banner != _lastBanner &&
        _active == null) {
      _lastBanner = banner;
      _enqueueStaffLine(banner);
    }

    if (widget.events.length > _lastEventCount) {
      final fresh = widget.events.take(widget.events.length - _lastEventCount);
      _lastEventCount = widget.events.length;
      for (final e in fresh) {
        if (e.kind == VoiceRoomRealtimeKind.join &&
            VoiceOfficialJoin.isEntranceWorthy(content: e.message)) {
          _enqueueStaffLine(e.message);
        }
      }
    }

    final joins = widget.messages
        .where((m) => m.kind == ChatMessageKind.systemJoin)
        .toList();
    if (joins.length > _lastJoinMsgCount) {
      final fresh = joins.skip(_lastJoinMsgCount);
      _lastJoinMsgCount = joins.length;
      for (final m in fresh) {
        if (VoiceOfficialJoin.isEntranceWorthy(
          content: m.content,
          membership: m.user?.membership,
          chatRole: m.user?.chatRole,
        )) {
          _enqueueStaffLine(m.content, user: m.user);
        }
      }
    }
  }

  void _enqueueStaffLine(String raw, {ChatRoomUserRef? user}) {
    _queue.add(_parseStaffLine(raw, user: user));
    if (_active == null) _showNext();
  }

  _StaffJoinLine _parseStaffLine(String raw, {ChatRoomUserRef? user}) {
    final text = raw.trim();
    final rank = VoiceStaffRankParser.resolve(
      username: user?.nickname ?? user?.name,
      chatRole: user?.chatRole,
    );
    var roleLabel = 'Yetkili';
    var roleColor = AppThemeColors.liveRed;
    var icon = Icons.admin_panel_settings_rounded;
    var name = user?.displayName ?? text;

    switch (rank) {
      case VoiceStaffRank.founder:
        roleLabel = 'Kurucu';
        roleColor = VoiceRoomTokens.gold;
        icon = Icons.workspace_premium_rounded;
      case VoiceStaffRank.admin:
        roleLabel = 'Admin';
        roleColor = AppThemeColors.liveRed;
        icon = Icons.admin_panel_settings_rounded;
      case VoiceStaffRank.sop:
      case VoiceStaffRank.op:
        roleLabel = 'Mod';
        roleColor = VoiceRoomTokens.neonPurple;
        icon = Icons.shield_rounded;
      case VoiceStaffRank.voice:
        roleLabel = 'DJ';
        roleColor = AppThemeColors.accentPink;
        icon = Icons.headphones_rounded;
      case VoiceStaffRank.none:
        final m = user?.membership?.toLowerCase() ?? '';
        if (m.contains('gold') || m.contains('vip')) {
          roleLabel = 'VIP';
          roleColor = AppThemeColors.coinGold;
          icon = Icons.diamond_rounded;
        } else if (text.contains('Admin') || text.contains('admin')) {
          roleLabel = 'Admin';
        }
    }

    if (user == null) {
      final joinedMatch = RegExp(
        r'^(.+?)\s+(odaya|giriş|katıldı|girdi)',
        caseSensitive: false,
      ).firstMatch(text);
      if (joinedMatch != null) {
        name = joinedMatch.group(1)?.trim() ?? text;
      } else if (text.contains(' — ')) {
        name = text.split(' — ').first.trim();
      }
      name = VoiceOfficialJoin.formatEntranceBanner(name).replaceAll('📣 ', '');
    }

    if (name.length > 28) name = '${name.substring(0, 26)}…';
    return _StaffJoinLine(
      name: name.isEmpty ? 'Kullanıcı' : name,
      roleLabel: roleLabel,
      roleColor: roleColor,
      icon: icon,
    );
  }

  Future<void> _showNext() async {
    if (!mounted || _queue.isEmpty) return;
    _active = _queue.removeAt(0);
    _ctrl?.dispose();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl!,
      curve: const Interval(0, 0.22, curve: Curves.easeOutCubic),
    ));
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 68,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_ctrl!);
    setState(() {});
    await _ctrl!.forward();
    if (!mounted) return;
    setState(() {
      _active = null;
    });
    if (_queue.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) _showNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    _collectNewEntries();
    final line = _active;
    if (line == null || _ctrl == null || _slide == null || _fade == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 52,
      left: 8,
      right: 8,
      child: FadeTransition(
        opacity: _fade!,
        child: SlideTransition(
          position: _slide!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  line.roleColor.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(color: line.roleColor.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: line.roleColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: line.roleColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: line.roleColor.withValues(alpha: 0.55)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(line.icon, size: 13, color: line.roleColor),
                        const SizedBox(width: 4),
                        Text(
                          line.roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: line.roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: line.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: line.roleColor,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          const TextSpan(
                            text: 'odaya giriş yaptı',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
