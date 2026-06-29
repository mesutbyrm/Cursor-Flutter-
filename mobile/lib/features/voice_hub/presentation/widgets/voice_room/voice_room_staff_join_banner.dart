import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_staff_chat_style.dart';

/// Yetkili giriş — koltuk altı sağdan sola kayan bant (tüm kullanıcılar).
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
    required this.line,
    required this.accent,
  });

  final String line;
  final Color accent;
}

class _VoiceRoomStaffJoinBannerState extends State<VoiceRoomStaffJoinBanner>
    with SingleTickerProviderStateMixin {
  final _queue = <_StaffJoinLine>[];
  final _seen = <String>{};
  _StaffJoinLine? _active;
  AnimationController? _scroll;
  String? _lastBanner;
  int _lastEventCount = 0;
  int _lastJoinMsgCount = 0;
  double _segmentWidth = 0;

  static const _style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  @override
  void dispose() {
    _scroll?.dispose();
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
    if (banner != null && banner.isNotEmpty && banner != _lastBanner) {
      _lastBanner = banner;
      _enqueueFromRaw(banner);
    }

    if (widget.events.length > _lastEventCount) {
      final fresh = widget.events.take(widget.events.length - _lastEventCount);
      _lastEventCount = widget.events.length;
      for (final e in fresh) {
        if (e.kind == VoiceRoomRealtimeKind.join &&
            VoiceStaffChatStyle.isStaffEntry(content: e.message)) {
          _enqueueFromRaw(e.message);
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
          _enqueueFromRaw(m.content, user: m.user);
        }
      }
    }
  }

  void _enqueueFromRaw(String raw, {ChatRoomUserRef? user}) {
    final key = VoiceOfficialJoin.entranceDedupeKey(raw);
    if (!_seen.add(key)) return;
    final line = _parseStaffLine(raw, user: user);
    _queue.add(line);
    if (_active == null) _showNext();
  }

  _StaffJoinLine _parseStaffLine(String raw, {ChatRoomUserRef? user}) {
    var name = user?.displayName ?? '';
    if (name.isEmpty) {
      name = VoiceOfficialJoin.formatEntranceBanner(raw)
          .replaceAll('📣 ', '')
          .trim();
      final parsed = RegExp(
        r'^(.+?)\s+(odaya|giriş|katıldı|girdi)',
        caseSensitive: false,
      ).firstMatch(name);
      if (parsed != null) {
        name = parsed.group(1)?.trim() ?? name;
      } else if (name.contains(' — ')) {
        name = name.split(' — ').first.trim();
      }
      name = name
          .replaceFirst(RegExp(r'^[~&@%+]\s*'), '')
          .replaceFirst(
            RegExp(
              r'^(ADMIN|MODERATOR|MOD|KURUCU|YETKİLİ|YETKILI|SOP)\s+',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }

    final accent = VoiceStaffChatStyle.accentForUser(user);
    return _StaffJoinLine(
      line: VoiceStaffChatStyle.formatStaffEntryLine(name, user: user),
      accent: accent,
    );
  }

  Future<void> _showNext() async {
    if (!mounted || _queue.isEmpty) return;
    _active = _queue.removeAt(0);
    _scroll?.dispose();
    _scroll = null;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() {
    if (!mounted || _active == null) return;
    final line = _active!.line;
    final painter = TextPainter(
      text: TextSpan(text: '$line     ', style: _style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _segmentWidth = painter.width;
    final viewport = context.size?.width ?? 320;
    final durationMs = (_segmentWidth * 22).clamp(4500, 14000).round();
    _scroll = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _scroll!.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _active = null;
      _scroll?.dispose();
      _scroll = null;
      if (_queue.isNotEmpty) {
        unawaited(_showNext());
      } else {
        setState(() {});
      }
    });
    _scroll!.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _collectNewEntries();
    final line = _active;
    if (line == null || _scroll == null) {
      return const SizedBox.shrink();
    }

    final label = line.line;
    final marquee = AnimatedBuilder(
      animation: _scroll!,
      builder: (context, _) {
        final dx = -_scroll!.value * _segmentWidth;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label     ', style: _style),
              Text('$label     ', style: _style),
            ],
          ),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              line.accent.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.82),
            ],
          ),
          border: Border.all(color: line.accent.withValues(alpha: 0.55)),
          boxShadow: VoiceRoomTokens.neonGlow(line.accent, blur: 10),
        ),
        child: SizedBox(
          height: 34,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: marquee,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
