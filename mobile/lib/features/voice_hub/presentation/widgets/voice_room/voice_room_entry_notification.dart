import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/voice_official_join.dart';
import '../../theme/voice_room_tokens.dart';

/// Yetkili / VIP oda giriş bildirimi — tasarım referansı kartı.
class VoiceRoomEntryNotificationCard extends StatelessWidget {
  const VoiceRoomEntryNotificationCard({
    super.key,
    required this.message,
    this.roomName,
  });

  final String? message;
  final String? roomName;

  @override
  Widget build(BuildContext context) {
    final raw = message?.trim() ?? '';
    if (raw.isEmpty) return const SizedBox.shrink();

    final line = VoiceOfficialJoin.formatEntranceBanner(raw, roomName: roomName);
    final name = _extractName(line);
    final subtitle = roomName?.trim().isNotEmpty == true
        ? '$name sohbet odasına giriş yaptı.'
        : '$name odaya giriş yaptı.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppThemeColors.coinGold.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppThemeColors.coinGold.withValues(alpha: 0.65),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppThemeColors.coinGold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name odaya giriş yaptı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.45),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _extractName(String line) {
    final t = line.replaceAll('📣', '').trim();
    final idx = t.toLowerCase().indexOf(' odaya');
    if (idx > 0) return t.substring(0, idx).trim();
    final idx2 = t.toLowerCase().indexOf(' sohbet');
    if (idx2 > 0) return t.substring(0, idx2).trim();
    return t.isNotEmpty ? t : 'Admin';
  }
}
