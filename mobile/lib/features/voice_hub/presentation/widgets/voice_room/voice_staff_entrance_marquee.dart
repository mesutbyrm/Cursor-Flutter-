import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/voice_official_join.dart';

/// Yetkili girişi — kullanıcı adıyla kısa şerit (MODERATÖR etiketi yok).
class VoiceStaffEntranceMarquee extends StatelessWidget {
  const VoiceStaffEntranceMarquee({
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentPurple.withValues(alpha: 0.75),
                AppThemeColors.accentPink.withValues(alpha: 0.65),
                AppThemeColors.coinGold.withValues(alpha: 0.35),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Colors.white,
                      height: 1.25,
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
