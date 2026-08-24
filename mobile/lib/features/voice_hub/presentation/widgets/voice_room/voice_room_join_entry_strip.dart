import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';

/// Koltuk altı giriş şeridi — yalnızca normal üyeler, sağdan sola kayarak kaybolur.
class VoiceRoomJoinEntryStrip extends StatefulWidget {
  const VoiceRoomJoinEntryStrip({
    super.key,
    required this.events,
    required this.messages,
  });

  final List<VoiceRoomRealtimeEvent> events;
  final List<ChatRoomMessage> messages;

  @override
  State<VoiceRoomJoinEntryStrip> createState() => _VoiceRoomJoinEntryStripState();
}

class _JoinLine {
  _JoinLine({
    required this.name,
    required this.roleLabel,
    required this.roleColor,
    required this.icon,
    required this.isLeave,
  });

  final String name;
  final String roleLabel;
  final Color roleColor;
  final IconData icon;
  final bool isLeave;
}

class _VoiceRoomJoinEntryStripState extends State<VoiceRoomJoinEntryStrip>
    with SingleTickerProviderStateMixin {
  final _queue = <_JoinLine>[];
  _JoinLine? _active;
  AnimationController? _ctrl;
  Animation<Offset>? _slide;
  Animation<double>? _fade;
  // Olay listesi başa eklenip 40'ta kırpıldığı için uzunluk farkı güvenilir
  // değil (dolduğunda uzunluk sabit kalıp yeni girişler görünmez oluyordu).
  // Yeni olayları kimlik (identical) ile tespit ediyoruz.
  VoiceRoomRealtimeEvent? _lastSeenEvent;
  int _lastJoinMsgCount = 0;
  int _lastLeaveMsgCount = 0;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomJoinEntryStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _collectNewEntries();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _baselineFromHistory());
  }

  void _baselineFromHistory() {
    _lastJoinMsgCount = widget.messages
        .where((m) => m.kind == ChatMessageKind.systemJoin)
        .length;
    _lastLeaveMsgCount = widget.messages
        .where((m) => m.kind == ChatMessageKind.systemLeave)
        .length;
    if (widget.events.isNotEmpty) {
      _lastSeenEvent = widget.events.first;
    }
  }

  bool _isStaffJoin(String content, ChatRoomUserRef? user) {
    return VoiceOfficialJoin.isEntranceWorthy(
      content: content,
      membership: user?.membership,
      chatRole: user?.chatRole,
    );
  }

  void _collectNewEntries() {
    final events = widget.events;
    if (events.isNotEmpty) {
      // events: en yeni başta. Daha önce görülen olaya (kimlik) kadar topla.
      final fresh = <VoiceRoomRealtimeEvent>[];
      for (final e in events) {
        if (identical(e, _lastSeenEvent)) break;
        fresh.add(e);
      }
      _lastSeenEvent = events.first;
      // Kronolojik sırada (eskiden yeniye) kuyruğa al.
      for (final e in fresh.reversed) {
        if (e.kind == VoiceRoomRealtimeKind.join &&
            !_isStaffJoin(e.message, null)) {
          _enqueue(_parseLine(e.message, user: null, isLeave: false));
        } else if (e.kind == VoiceRoomRealtimeKind.leave) {
          _enqueue(_parseLine(e.message, user: null, isLeave: true));
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
        if (!_isStaffJoin(m.content, m.user)) {
          _enqueue(_parseLine(m.content, user: m.user, isLeave: false));
        }
      }
    }

    final leaves = widget.messages
        .where((m) => m.kind == ChatMessageKind.systemLeave)
        .toList();
    if (leaves.length > _lastLeaveMsgCount) {
      final fresh = leaves.skip(_lastLeaveMsgCount);
      _lastLeaveMsgCount = leaves.length;
      for (final m in fresh) {
        _enqueue(_parseLine(m.content, user: m.user, isLeave: true));
      }
    }
  }

  _JoinLine _parseLine(
    String raw, {
    ChatRoomUserRef? user,
    required bool isLeave,
  }) {
    final text = raw.trim();
    var roleLabel = 'Üye';
    var roleColor = VoiceRoomTokens.neonBlue;
    var icon = Icons.person_rounded;
    var name = user?.displayName ?? text;

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
    }

    if (name.length > 28) name = '${name.substring(0, 26)}…';
    return _JoinLine(
      name: name.isEmpty ? 'Kullanıcı' : name,
      roleLabel: roleLabel,
      roleColor: isLeave ? Colors.white54 : roleColor,
      icon: isLeave ? Icons.logout_rounded : icon,
      isLeave: isLeave,
    );
  }

  void _enqueue(_JoinLine line) {
    while (_queue.length > 1) {
      _queue.removeAt(0);
    }
    _queue.add(line);
    if (_active == null) _showNext();
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: FadeTransition(
        opacity: _fade!,
        child: SlideTransition(
          position: _slide!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  line.roleColor.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(color: line.roleColor.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: line.roleColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: line.roleColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(line.icon, size: 12, color: line.roleColor),
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
                  const SizedBox(width: 8),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppThemeColors.coinGold,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: line.isLeave ? 'çıkış yaptı' : 'giriş yaptı',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: line.isLeave
                                  ? Colors.white54
                                  : Colors.white70,
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
