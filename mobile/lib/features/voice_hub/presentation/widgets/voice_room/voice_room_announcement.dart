import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';

/// Duyuru kutusu — oda açıklaması (canlifal.com `descTr`).
class VoiceRoomAnnouncement extends StatelessWidget {
  const VoiceRoomAnnouncement({
    super.key,
    required this.text,
    this.onDismiss,
  });

  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppDesign.accentPurple.withValues(alpha: 0.35),
                AppDesign.bgPurpleGlow.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppDesign.accentPurple.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_rounded, color: AppDesign.accentPink, size: 22),
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
                        color: AppDesign.accentPink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppDesign.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppDesign.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppDesign.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
        ),
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
        style: const TextStyle(fontSize: 10, color: AppDesign.textSecondary),
      ),
    );
  }
}
