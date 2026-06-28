import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../theme/voice_room_tokens.dart';

/// Koltuk altı tek giriş şeridi — sağdan sola kayarak kaybolur.
class VoiceRoomJoinEntryStrip extends StatefulWidget {
  const VoiceRoomJoinEntryStrip({
    super.key,
    required this.events,
    required this.messages,
    this.enterBanner,
  });

  final List<VoiceRoomRealtimeEvent> events;
  final List<ChatRoomMessage> messages;
  final String? enterBanner;

  @override
  State<VoiceRoomJoinEntryStrip> createState() => _VoiceRoomJoinEntryStripState();
}

class _JoinLine {
  _JoinLine({
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

class _VoiceRoomJoinEntryStripState extends State<VoiceRoomJoinEntryStrip>
    with SingleTickerProviderStateMixin {
  final _queue = <_JoinLine>[];
  _JoinLine? _active;
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
  void didUpdateWidget(covariant VoiceRoomJoinEntryStrip oldWidget) {
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
      _enqueue(_parseLine(banner));
    }

    if (widget.events.length > _lastEventCount) {
      final fresh = widget.events.take(widget.events.length - _lastEventCount);
      _lastEventCount = widget.events.length;
      for (final e in fresh) {
        if (e.kind == VoiceRoomRealtimeKind.join) {
          _enqueue(_parseLine(e.message));
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
        _enqueue(_parseLine(m.content));
      }
    }
  }

  _JoinLine _parseLine(String raw) {
    final text = raw.trim();
    var roleLabel = 'Üye';
    var roleColor = VoiceRoomTokens.neonBlue;
    var icon = Icons.person_rounded;
    var name = text;

    if (text.contains('Admin') || text.contains('admin')) {
      roleLabel = 'Admin';
      roleColor = AppThemeColors.liveRed;
      icon = Icons.admin_panel_settings_rounded;
    } else if (text.contains('VIP') || text.contains('vip')) {
      roleLabel = 'VIP';
      roleColor = AppThemeColors.coinGold;
      icon = Icons.diamond_rounded;
    } else if (text.contains('DJ') || text.contains('dj')) {
      roleLabel = 'DJ';
      roleColor = AppThemeColors.accentPink;
      icon = Icons.headphones_rounded;
    } else if (text.contains('Moderat') || text.contains('mod')) {
      roleLabel = 'Mod';
      roleColor = VoiceRoomTokens.neonPurple;
      icon = Icons.shield_rounded;
    }

    final joinedMatch = RegExp(r'^(.+?)\s+(odaya|giriş|katıldı|girdi)', caseSensitive: false)
        .firstMatch(text);
    if (joinedMatch != null) {
      name = joinedMatch.group(1)?.trim() ?? text;
    } else if (text.contains(' — ')) {
      name = text.split(' — ').first.trim();
    }

    if (name.length > 28) name = '${name.substring(0, 26)}…';
    return _JoinLine(
      name: name.isEmpty ? 'Kullanıcı' : name,
      roleLabel: roleLabel,
      roleColor: roleColor,
      icon: icon,
    );
  }

  void _enqueue(_JoinLine line) {
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
