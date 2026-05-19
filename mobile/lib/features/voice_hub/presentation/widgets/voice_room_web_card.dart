import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_design.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

/// Web `/chat` odalarına benzer neon kart.
class VoiceRoomWebCard extends StatelessWidget {
  const VoiceRoomWebCard({
    super.key,
    required this.room,
    required this.onTap,
    this.large = false,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: large ? 200 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppDesign.accentPurple.withValues(alpha: 0.45),
            ),
            boxShadow: AppDesign.glowShadow(AppDesign.accentPink, blur: 16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bg != null && bg.isNotEmpty)
                  CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover)
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3A1F5E), Color(0xFF120A1C)],
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(room.icon ?? '💬',
                              style: TextStyle(fontSize: large ? 32 : 24)),
                          const Spacer(),
                          if (room.displayOnline > 0) _OnlinePill(count: room.displayOnline),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        room.nameTr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: large ? 20 : 16,
                          height: 1.1,
                        ),
                      ),
                      if (room.descTr != null && room.descTr!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          room.descTr!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppDesign.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (room.ownerAvatarUrl != null)
                            CircleAvatar(
                              radius: 14,
                              backgroundImage:
                                  CachedNetworkImageProvider(room.ownerAvatarUrl!),
                            )
                          else
                            const CircleAvatar(
                              radius: 14,
                              child: Icon(Icons.person, size: 16),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              room.ownerName ?? 'Moderatör',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ..._avatarStack(room.recentUserAvatars),
                          const SizedBox(width: 8),
                          ProfileGlass(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            borderRadius: 12,
                            blur: 8,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.headset_mic_rounded,
                                  size: 14,
                                  color: AppDesign.accentCyan
                                      .withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gir',
                                  style: TextStyle(
                                    color: AppDesign.accentCyan
                                        .withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0);
  }

  List<Widget> _avatarStack(List<String> urls) {
    if (urls.isEmpty) return const [];
    final show = urls.take(3).toList();
    return [
      SizedBox(
        width: 14.0 + (show.length - 1) * 12,
        height: 28,
        child: Stack(
          children: [
            for (var i = 0; i < show.length; i++)
              Positioned(
                left: i * 12.0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: CachedNetworkImageProvider(show[i]),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppDesign.onlineGreen.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppDesign.onlineGreen.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppDesign.onlineGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
