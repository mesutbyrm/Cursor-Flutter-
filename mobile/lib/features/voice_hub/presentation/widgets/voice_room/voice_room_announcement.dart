import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';


/// Duyuru kutusu — oda açıklaması (canlifal.com `descTr`).
class VoiceRoomAnnouncement extends StatelessWidget {
  const VoiceRoomAnnouncement({
    super.key,
    required this.text,
    this.onDismiss,
    this.onEdit,
    this.progress,
    this.autoCloseLabel,
  });

  final String text;
  final VoidCallback? onDismiss;
  final VoidCallback? onEdit;
  final double? progress;
  final String? autoCloseLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeColors.accentPurple.withValues(alpha: 0.48),
            Colors.black.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppThemeColors.accentPurple.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: AppThemeColors.coinGold,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duyuru',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: AppThemeColors.coinGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: context.colors.onSurfaceMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.colors.onSurfaceMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
              ],
            ),
          ),
          if (autoCloseLabel != null || progress != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (autoCloseLabel != null)
                    Text(
                      autoCloseLabel!,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppThemeColors.coinGold.withValues(alpha: 0.85),
                      ),
                    ),
                  if (progress != null) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.white12,
                        color: AppThemeColors.coinGold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Son sistem katılım / duyuru şeridi.
class VoiceRoomSystemBanner extends StatelessWidget {
  const VoiceRoomSystemBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        '📣 $message',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant),
      ),
    );
  }
}
