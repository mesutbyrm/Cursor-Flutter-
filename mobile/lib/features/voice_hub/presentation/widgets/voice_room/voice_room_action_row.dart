import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/chat_room_message.dart';

class VoiceRoomActionRow extends StatelessWidget {
  const VoiceRoomActionRow({
    super.key,
    required this.dj,
    this.showMusicCard = true,
    this.onMusicTap,
    this.onDjTap,
  });

  final ChatRoomDjState dj;
  final bool showMusicCard;
  final VoidCallback? onMusicTap;
  final VoidCallback? onDjTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMusicCard)
          Expanded(
            child: _ActionTile(
              onTap: onMusicTap,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF0080), Color(0xFF8E2DE2)],
            ),
            child: Row(
              children: [
                Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Müzik Aç',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        dj.musicQueue.isEmpty
                            ? '${dj.musicRequestCost} jeton · sıra boş'
                            : 'Sıra: ${dj.musicQueue.length} · ${dj.musicRequestCost} jeton',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      SizedBox(height: 4),
                      _WaveBars(active: dj.musicQueue.isNotEmpty || dj.playing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showMusicCard) const SizedBox(width: 10),
        Expanded(
          flex: showMusicCard ? 1 : 2,
          child: _ActionTile(
            onTap: onDjTap,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF25F4EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                Icon(Icons.headphones_rounded, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DJ ${dj.djCount}/5',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      _DjAvatars(users: dj.djUsers),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.gradient,
    required this.child,
    this.onTap,
  });

  final LinearGradient gradient;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPurple, blur: 14),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(12, (i) {
        final h = active ? 4.0 + (i % 4) * 4.0 : 3.0;
        return Container(
          width: 3,
          height: h,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 0.85 : 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _DjAvatars extends StatelessWidget {
  const _DjAvatars({required this.users});

  final List<ChatRoomUserRef> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Text(
        'Kuyruk boş',
        style: TextStyle(
          fontSize: 9,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
    }
    return SizedBox(
      height: 22,
      child: Stack(
        children: [
          for (var i = 0; i < users.length && i < 5; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipOval(
                  child: () {
                    final img = users[i].image;
                    if (img != null && img.isNotEmpty) {
                      return CachedNetworkImage(imageUrl: img, fit: BoxFit.cover);
                    }
                    return ColoredBox(
                      color: AppThemeColors.dark.scaffoldBackground,
                      child: const Icon(Icons.person, size: 12),
                    );
                  }(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
