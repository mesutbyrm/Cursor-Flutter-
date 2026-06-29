import 'package:flutter/material.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../../domain/entities/voice_room_realtime_event.dart';
import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_staff_chat_style.dart';

/// Faz 9 — yetkili giriş animasyonu: koltuk altı, sağdan sola.
/// Örnek: «👑 Admin Mesut odaya giriş yaptı» — tüm kullanıcılar görür.
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
    _ctrl?.dispose();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl!,
      curve: const Interval(0, 0.25, curve: Curves.easeOutCubic),
    ));
    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl!);
    setState(() {});
    await _ctrl!.forward();
    if (!mounted) return;
    setState(() => _active = null);
    if (_queue.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 140));
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
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: FadeTransition(
        opacity: _fade!,
        child: SlideTransition(
          position: _slide!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  line.accent.withValues(alpha: 0.38),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
              border: Border.all(color: line.accent.withValues(alpha: 0.65)),
              boxShadow: VoiceRoomTokens.neonGlow(line.accent, blur: 14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(
                line.line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.96),
                  shadows: VoiceStaffChatStyle.nameGlow(line.accent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
