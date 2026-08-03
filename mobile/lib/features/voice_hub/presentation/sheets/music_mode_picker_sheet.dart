import 'package:flutter/material.dart';

import '../theme/voice_room_tokens.dart';

/// Şarkı seçiminden sonra — Sadece Ses / Videolu jeton seçimi (web ile aynı).
Future<bool?> showMusicModePickerSheet(
  BuildContext context, {
  required int audioCost,
  required int videoCost,
  String? songTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Müzik gönderme türü',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          if (songTitle != null && songTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              songTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Jeton ücreti seçiminize göre kesilir',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          _ModeTile(
            icon: Icons.music_note_rounded,
            title: 'Sadece Ses Çal',
            subtitle: '$audioCost Jeton',
            gradient: const [Color(0xFF4A00E0), Color(0xFF8B5CF6)],
            onTap: () => Navigator.pop(ctx, false),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.music_video_rounded,
            title: 'Videolu Çal',
            subtitle: '$videoCost Jeton',
            gradient: const [Color(0xFFFF0080), Color(0xFF7B2FF7)],
            onTap: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('İptal', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.diamond_rounded,
                  color: VoiceRoomTokens.gold,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
