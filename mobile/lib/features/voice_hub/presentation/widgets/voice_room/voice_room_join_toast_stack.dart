import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../../domain/voice_official_join.dart';
import '../../utils/voice_staff_chat_style.dart';

/// Faz 7 — altta yığılan giriş bildirimleri: «Ali giriş yaptı.» (10 sn).
class VoiceRoomJoinToastStack extends StatefulWidget {
  const VoiceRoomJoinToastStack({
    super.key,
    required this.events,
    required this.messages,
    this.maxVisible = 5,
  });

  final List<VoiceRoomRealtimeEvent> events;
  final List<ChatRoomMessage> messages;
  final int maxVisible;

  @override
  State<VoiceRoomJoinToastStack> createState() => _VoiceRoomJoinToastStackState();
}

class _JoinToast {
  _JoinToast({required this.id, required this.line});

  final String id;
  final String line;
}

class _VoiceRoomJoinToastStackState extends State<VoiceRoomJoinToastStack> {
  final _visible = <_JoinToast>[];
  final _seen = <String>{};
  final _timers = <String, Timer>{};
  var _lastEventCount = 0;
  var _lastJoinMsgCount = 0;

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomJoinToastStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _collectNewEntries();
  }

  @override
  void initState() {
    super.initState();
    _collectNewEntries();
  }

  void _collectNewEntries() {
    if (widget.events.length > _lastEventCount) {
      final fresh = widget.events.take(widget.events.length - _lastEventCount);
      _lastEventCount = widget.events.length;
      for (final e in fresh) {
        if (e.kind == VoiceRoomRealtimeKind.join &&
            !VoiceStaffChatStyle.isStaffEntry(content: e.message)) {
          _enqueueFromRaw(e.message, user: null);
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
        if (VoiceStaffChatStyle.isStaffEntry(
          content: m.content,
          user: m.user,
        )) {
          continue;
        }
        _enqueueFromRaw(m.content, user: m.user);
      }
    }
  }

  void _enqueueFromRaw(String raw, {ChatRoomUserRef? user}) {
    if (VoiceStaffChatStyle.isStaffEntry(content: raw, user: user)) return;
    final name = _parseName(raw, user: user);
    if (name.isEmpty) return;
    final line = '$name giriş yaptı.';
    final key = VoiceOfficialJoin.entranceDedupeKey(raw);
    if (!_seen.add(key)) return;
    final id = '${DateTime.now().microsecondsSinceEpoch}_$name';
    setState(() {
      _visible.add(_JoinToast(id: id, line: line));
      while (_visible.length > widget.maxVisible) {
        final removed = _visible.removeAt(0);
        _timers.remove(removed.id)?.cancel();
      }
    });
    _timers[id]?.cancel();
    _timers[id] = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        _visible.removeWhere((t) => t.id == id);
      });
      _timers.remove(id);
    });
  }

  String _parseName(String raw, {ChatRoomUserRef? user}) {
    final fromUser = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : user?.name.trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;

    var text = raw.trim();
    text = text.replaceAll('📣', '').trim();
    final joinedMatch = RegExp(
      r'^(.+?)\s+(odaya|giriş|katıldı|girdi|joined)',
      caseSensitive: false,
    ).firstMatch(text);
    if (joinedMatch != null) {
      var name = joinedMatch.group(1)?.trim() ?? '';
      name = name.replaceFirst(RegExp(r'^[@~&%+]+\s*'), '').trim();
      if (name.isNotEmpty) return name;
    }
    if (text.contains(' — ')) {
      return text.split(' — ').first.trim();
    }
    final parsed = VoiceOfficialJoin.formatEntranceBanner(text);
    if (parsed.isNotEmpty) {
      final idx = parsed.toLowerCase().indexOf(' odaya');
      if (idx > 0) return parsed.substring(0, idx).trim();
      final idx2 = parsed.toLowerCase().indexOf(' giriş');
      if (idx2 > 0) return parsed.substring(0, idx2).trim();
    }
    return text.replaceFirst(RegExp(r'^[@~&%+]+\s*'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    _collectNewEntries();
    if (_visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final toast in _visible)
            _JoinToastLine(
              key: ValueKey(toast.id),
              text: toast.line,
            ),
        ],
      ),
    );
  }
}

class _JoinToastLine extends StatefulWidget {
  const _JoinToastLine({super.key, required this.text});

  final String text;

  @override
  State<_JoinToastLine> createState() => _JoinToastLineState();
}

class _JoinToastLineState extends State<_JoinToastLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 0,
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(
          widget.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.88),
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 8),
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
