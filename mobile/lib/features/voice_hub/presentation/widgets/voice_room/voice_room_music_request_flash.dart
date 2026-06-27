import 'package:flutter/material.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';

/// !istek / şarkı kuyruğu — Müzik & DJ satırının altında yanıp sönen duyuru.
class VoiceRoomMusicRequestFlash extends StatefulWidget {
  const VoiceRoomMusicRequestFlash({super.key, required this.message});

  final String? message;

  @override
  State<VoiceRoomMusicRequestFlash> createState() =>
      _VoiceRoomMusicRequestFlashState();
}

class _VoiceRoomMusicRequestFlashState extends State<VoiceRoomMusicRequestFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentPink.withValues(alpha: 0.9),
                AppThemeColors.accentPurple.withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPink.withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gelen sohbet satırından duyuru metni üretir.
abstract final class VoiceMusicRequestFlashText {
  static String? fromChatContent(String content, {String? userName}) {
    final raw = content.trim();
    if (raw.isEmpty) return null;

    final who = userName?.trim().isNotEmpty == true ? userName!.trim() : 'Bir dinleyici';

    final free = RegExp(
      r'\[SONG_REQUEST_FREE\]\s*[^\s|]+\|([^|]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (free != null) {
      return '🎵 $who şarkı isteği gönderdi: ${free.group(1)!.trim()}';
    }

    final sent = RegExp(
      r'şarkı isteği gönderdi:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (sent != null) {
      return '🎵 $who şarkı isteği gönderdi: ${sent.group(1)!.trim()}';
    }

    final cmd = RegExp(
      r'Şarkı isteği alındı.*[«"]([^»"]+)[»"]',
      caseSensitive: false,
    ).firstMatch(raw);
    if (cmd != null) {
      return '🎵 $who şarkı istedi: ${cmd.group(1)!.trim()}';
    }

    final queued = RegExp(
      r'"([^"]+)"\s+şarkısını istedi',
      caseSensitive: false,
    ).firstMatch(raw);
    if (queued != null) {
      return '🎵 $who «${queued.group(1)!.trim()}» sıraya eklendi';
    }

    final queueAdded = RegExp(
      r'📀\s*Şarkı kuyruğa eklendi',
      caseSensitive: false,
    ).hasMatch(raw);
    if (queueAdded) {
      return '🎵 Yeni şarkı kuyruğa eklendi';
    }

    final position = RegExp(
      r'🔢\s*Sıra:\s*#(\d+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (position != null) {
      return '🎵 Sıra: #${position.group(1)}';
    }

    if (raw.toLowerCase().startsWith('!istek') ||
        raw.toLowerCase().startsWith('/istek')) {
      final song = raw.replaceFirst(RegExp(r'^[!/]istek\s*', caseSensitive: false), '').trim();
      if (song.isNotEmpty) {
        return '🎵 $who şarkı istedi: $song';
      }
    }

    return null;
  }
}
