import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../domain/entities/chat_room_presence.dart';
import '../../theme/voice_room_tokens.dart';
import '../premium/voice_neon_avatar.dart';

/// Odadaki dinleyiciler — mikrofon koltuğunda olmayan kullanıcılar.
class VoiceRoomAudienceStrip extends StatelessWidget {
  const VoiceRoomAudienceStrip({
    super.key,
    required this.audience,
    required this.totalOnline,
    this.onUserTap,
    this.maxVisible = 12,
  });

  final List<ChatRoomPresence> audience;
  final int totalOnline;
  final void Function(ChatRoomPresence user)? onUserTap;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (audience.isEmpty && totalOnline <= 0) {
      return const SizedBox.shrink();
    }

    final visible = audience.take(maxVisible).toList();
    final extra = (totalOnline > visible.length ? totalOnline - visible.length : 0) +
        (audience.length > maxVisible ? audience.length - maxVisible : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 16,
            color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.9),
          ),
          SizedBox(width: 6),
          Text(
            'Odada $totalOnline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visible.length + (extra > 0 ? 1 : 0),
                separatorBuilder: (_, __) => SizedBox(width: 6),
                itemBuilder: (context, i) {
                  if (i < visible.length) {
                    final u = visible[i];
                    return GestureDetector(
                      onTap: onUserTap != null ? () => onUserTap!(u) : null,
                      child: VoiceNeonAvatar(
                        url: u.image,
                        size: 32,
                        speaking: u.isSpeaking,
                        onTap: onUserTap != null ? () => onUserTap!(u) : null,
                      ),
                    );
                  }
                  return Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '+$extra',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
