import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../theme/voice_room_tokens.dart';

/// Web sohbet odası üst bar — oda adı, ID, çevrimiçi, galeri, ayarlar, çıkış.
class VoiceWebRoomHeader extends StatelessWidget {
  const VoiceWebRoomHeader({
    super.key,
    required this.room,
    required this.onlineCount,
    required this.onBack,
    required this.onExit,
    this.onAudience,
    this.onGallery,
    this.onSettings,
    this.verified = true,
  });

  final VoiceRoomEntity room;
  final int onlineCount;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback? onAudience;
  final VoidCallback? onGallery;
  final VoidCallback? onSettings;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final shortId = room.apiRoomKey.length > 10
        ? room.apiRoomKey.substring(0, 10)
        : room.apiRoomKey;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: Row(
            children: [
              _GlassIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Clipboard.setData(ClipboardData(text: room.apiRoomKey)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              room.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: VoiceRoomTokens.neonPurple,
                                shape: BoxShape.circle,
                                boxShadow: VoiceRoomTokens.neonGlow(
                                  VoiceRoomTokens.neonPurple,
                                  blur: 8,
                                ),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $shortId',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted.withValues(alpha: 0.95),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _OnlineChip(count: onlineCount, onTap: onAudience),
              const SizedBox(width: 4),
              _GlassIconBtn(
                icon: Icons.photo_library_outlined,
                onTap: onGallery,
              ),
              _GlassIconBtn(
                icon: Icons.settings_rounded,
                onTap: onSettings,
              ),
              _GlassIconBtn(
                icon: Icons.power_settings_new_rounded,
                color: AppColors.liveRed,
                onTap: onExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt_rounded,
                size: 16,
                color: count > 0 ? AppColors.onlineGreen : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: count > 0 ? AppColors.onlineGreen : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({
    required this.icon,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: color ?? Colors.white.withValues(alpha: 0.92)),
    );
  }
}

/// Admin / oda sahibi bilgi hapı (telefon ikonu + ID).
class VoiceWebRoomInfoPill extends StatelessWidget {
  const VoiceWebRoomInfoPill({
    super.key,
    required this.room,
    this.ownerName,
    this.ownerAvatarUrl,
  });

  final VoiceRoomEntity room;
  final String? ownerName;
  final String? ownerAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final label = ownerName?.trim().isNotEmpty == true
        ? ownerName!.trim()
        : (room.ownerName?.trim().isNotEmpty == true
            ? room.ownerName!.trim()
            : 'Admin');
    final shortId = room.apiRoomKey.length > 12
        ? '${room.apiRoomKey.substring(0, 12)}…'
        : room.apiRoomKey;

    return Center(
      child: GestureDetector(
        onTap: () => Clipboard.setData(ClipboardData(text: room.apiRoomKey)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
            ),
            boxShadow: VoiceRoomTokens.neonGlow(
              VoiceRoomTokens.neonPurple,
              blur: 12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white12,
                backgroundImage: ownerAvatarUrl != null && ownerAvatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(ownerAvatarUrl!)
                    : null,
                child: ownerAvatarUrl == null || ownerAvatarUrl!.isEmpty
                    ? const Icon(Icons.call_rounded, size: 14, color: VoiceRoomTokens.gold)
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    shortId,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textMuted.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.copy_rounded,
                size: 12,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
