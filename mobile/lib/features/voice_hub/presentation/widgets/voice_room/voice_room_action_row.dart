import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/chat_room_message.dart';

class VoiceRoomActionRow extends StatelessWidget {
  const VoiceRoomActionRow({
    super.key,
    required this.dj,
    this.showMusicCard = true,
    this.showPkCard = false,
    this.pkActive = false,
    this.onMusicTap,
    this.onDjTap,
    this.onPkTap,
  });

  final ChatRoomDjState dj;
  final bool showMusicCard;
  final bool showPkCard;
  final bool pkActive;
  final VoidCallback? onMusicTap;
  final VoidCallback? onDjTap;
  final VoidCallback? onPkTap;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];

    if (showMusicCard) {
      tiles.add(
        Expanded(
          child: _ActionTile(
            onTap: onMusicTap,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF0080), Color(0xFF8E2DE2)],
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Müzik Aç',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        dj.musicQueue.isEmpty
                            ? '${dj.musicRequestCost} jeton'
                            : 'Sıra: ${dj.musicQueue.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _WaveBars(active: dj.musicQueue.isNotEmpty || dj.playing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    tiles.add(
      Expanded(
        child: _ActionTile(
          onTap: onDjTap,
          gradient: const LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF25F4EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Row(
            children: [
              const Icon(Icons.headphones_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DJ ${dj.djCount}/5',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _DjAvatars(users: dj.djUsers),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (showPkCard) {
      tiles.add(
        Expanded(
          child: _ActionTile(
            onTap: onPkTap,
            gradient: LinearGradient(
              colors: pkActive
                  ? const [Color(0xFFFF5252), Color(0xFFFFB300)]
                  : const [Color(0xFFB832FF), Color(0xFF6A1B9A)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  pkActive ? Icons.flash_on_rounded : Icons.sports_mma_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  pkActive ? 'PK' : 'PK',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          tiles[i],
        ],
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppThemeColors.glowShadow(
              AppThemeColors.accentPurple,
              blur: 10,
            ),
          ),
          child: child,
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
      children: List.generate(8, (i) {
        final h = active ? 3.0 + (i % 4) * 3.0 : 2.5;
        return Container(
          width: 2,
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
          fontSize: 8,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
    }
    return SizedBox(
      height: 16,
      child: Stack(
        children: [
          for (var i = 0; i < users.length && i < 5; i++)
            Positioned(
              left: i * 11.0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: ClipOval(
                  child: () {
                    final img = users[i].image;
                    if (img != null && img.isNotEmpty) {
                      return CachedNetworkImage(imageUrl: img, fit: BoxFit.cover);
                    }
                    return ColoredBox(
                      color: AppThemeColors.dark.scaffoldBackground,
                      child: const Icon(Icons.person, size: 10),
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
