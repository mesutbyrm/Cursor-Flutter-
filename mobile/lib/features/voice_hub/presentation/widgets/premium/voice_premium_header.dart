import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_glass.dart';

class VoicePremiumHeader extends StatelessWidget {
  const VoicePremiumHeader({
    super.key,
    required this.room,
    required this.onlineCount,
    required this.onBack,
    required this.onExit,
    this.onShare,
    this.onAudience,
    this.weeklyRank = 3,
    this.isOwner = false,
  });

  final VoiceRoomEntity room;
  final int onlineCount;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback? onShare;
  final VoidCallback? onAudience;
  final int weeklyRank;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final shortId =
        room.id.length > 10 ? '${room.id.substring(0, 10)}…' : room.id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        Expanded(
          child: VoiceGlass(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(room.icon ?? '💜', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: room.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Oda ID kopyalandı')),
                          );
                        },
                        child: Text(
                          'ID $shortId · $onlineCount çevrimiçi',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onShare != null)
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 20),
                  ),
                IconButton(
                  onPressed: onExit,
                  icon: const Icon(
                    Icons.power_settings_new_rounded,
                    color: AppColors.liveRed,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            VoiceGlass(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: 14,
              onTap: onAudience,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_rounded,
                      size: 16, color: VoiceRoomTokens.neonBlue),
                  const SizedBox(width: 4),
                  Text(
                    '$onlineCount',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: VoiceRoomTokens.fabGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple),
              ),
              child: Text(
                'Haftalık #$weeklyRank',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
