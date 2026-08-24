import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/live_gift_event.dart';
import '../../../../gifts/presentation/sync/gift_session_controller.dart';

class _SenderTag {
  _SenderTag({
    required this.id,
    required this.senderId,
    required this.name,
  });

  final String id;
  final String senderId;
  final String name;
}

/// Koltuk alanının sol altında — son 3 hediye gönderen, 4 sn karararak kapanır.
class VoiceGiftSenderTagsPanel extends ConsumerStatefulWidget {
  const VoiceGiftSenderTagsPanel({
    super.key,
    required this.sessionKey,
  });

  final String sessionKey;

  @override
  ConsumerState<VoiceGiftSenderTagsPanel> createState() =>
      _VoiceGiftSenderTagsPanelState();
}

class _VoiceGiftSenderTagsPanelState
    extends ConsumerState<VoiceGiftSenderTagsPanel> {
  final List<_SenderTag> _visible = [];
  final Map<String, int> _counts = {};
  final Map<String, Timer> _timers = {};

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _register(LiveGiftEvent event) {
    final senderId = (event.senderId ?? event.senderName).trim();
    if (senderId.isEmpty) return;
    final name = event.senderName.trim().isNotEmpty
        ? event.senderName.trim()
        : 'Biri';
    final qty = event.quantity > 0 ? event.quantity : 1;
    _counts[senderId] = (_counts[senderId] ?? 0) + qty;

    final tag = _SenderTag(
      id: '${event.id}-$senderId',
      senderId: senderId,
      name: name,
    );
    setState(() {
      _visible.removeWhere((t) => t.id == tag.id);
      _visible.insert(0, tag);
      while (_visible.length > 3) {
        _visible.removeLast();
      }
    });

    _timers[tag.id]?.cancel();
    _timers[tag.id] = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _visible.removeWhere((t) => t.id == tag.id));
      _timers.remove(tag.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LiveGiftEvent?>(
      giftSessionProvider(widget.sessionKey).select((s) => s.latestEvent),
      (prev, next) {
        if (next != null && next.id != prev?.id) _register(next);
      },
    );

    if (_visible.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 8,
      bottom: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tag in _visible)
            _FadingNameChip(
              key: ValueKey(tag.id),
              name: tag.name,
              count: _counts[tag.senderId] ?? 1,
            ),
        ],
      ),
    );
  }
}

class _FadingNameChip extends StatefulWidget {
  const _FadingNameChip({
    super.key,
    required this.name,
    required this.count,
  });

  final String name;
  final int count;

  @override
  State<_FadingNameChip> createState() => _FadingNameChipState();
}

class _FadingNameChipState extends State<_FadingNameChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.72, 1, curve: Curves.easeIn),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            '${widget.name} ×${widget.count}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
