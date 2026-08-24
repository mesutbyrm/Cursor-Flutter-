import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

/// Üst çevrimiçi kutusu — yalnızca çevrimiçi sayısı (hediye atanlar koltuk altında).
class VoiceOnlineGiftBox extends ConsumerWidget {
  const VoiceOnlineGiftBox({
    super.key,
    required this.onlineCount,
    this.onTap,
  });

  final int onlineCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(minWidth: 72, maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppThemeColors.onlineGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 14,
                        color: onlineCount > 0
                            ? AppThemeColors.onlineGreen
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$onlineCount çevrimiçi',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: onlineCount > 0
                              ? AppThemeColors.onlineGreen
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
