import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';

/// Koltuk altı "şu an çalan şarkı" şeridi — açık şeffaf yeşil kutu.
/// Çalan şarkı + isteyen kişi (yanıp söner) + sıradaki şarkı. Yetkili
/// için müziği kapatma düğmesi.
class VoiceRoomNowPlayingBar extends ConsumerWidget {
  const VoiceRoomNowPlayingBar({
    super.key,
    required this.roomKey,
    required this.canControl,
  });

  final String roomKey;
  final bool canControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = ref.watch(
      voiceRoomLiveProvider(roomKey).select((s) => s.dj),
    );
    final now = dj.nowPlaying;
    if (!dj.musicEnabled || now == null) {
      return const SizedBox.shrink();
    }

    final title = now.title.trim().isNotEmpty ? now.title.trim() : 'Şarkı';
    final requester = now.requestedBy?.displayName.trim();
    final giftTo = now.giftTo?.trim();

    // Sıradaki şarkı — çalandan farklı ilk kuyruk öğesi.
    String? nextTitle;
    for (final q in dj.musicQueue) {
      if (q.id != now.id && q.title.trim().isNotEmpty) {
        nextTitle = q.title.trim();
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      child: Container(
        decoration: BoxDecoration(
          // Açık şeffaf yeşil kutu.
          color: const Color(0x3322C55E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x5522C55E), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded,
                color: Color(0xFF4ADE80), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (requester != null && requester.isNotEmpty)
                    _BlinkingText(
                      text: giftTo != null && giftTo.isNotEmpty
                          ? '$requester → $giftTo istedi'
                          : '$requester istedi',
                    ),
                  if (nextTitle != null)
                    Text(
                      'Sıradaki: $nextTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Müziği kapat',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close_rounded,
                  color: Color(0xFFFF6B6B), size: 22),
              onPressed: () => unawaited(
                ref
                    .read(voiceRoomLiveProvider(roomKey).notifier)
                    .closeMusicPlayer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingText extends StatefulWidget {
  const _BlinkingText({required this.text});

  final String text;

  @override
  State<_BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<_BlinkingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF86EFAC),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
