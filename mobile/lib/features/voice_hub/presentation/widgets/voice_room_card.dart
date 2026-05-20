import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_design.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

/// Sesli oda listesi kartı — tamamen Flutter neon arayüz.
class VoiceRoomCard extends StatelessWidget {
  const VoiceRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.large = false,
    this.highlight = false,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;
  final bool large;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    final borderColor = highlight
        ? AppDesign.coinGold.withValues(alpha: 0.7)
        : AppDesign.accentPurple.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: highlight ? 2 : 1),
            boxShadow: AppDesign.glowShadow(
              highlight ? AppDesign.coinGold : AppDesign.accentPink,
              blur: highlight ? 20 : 14,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: large ? 168 : 132,
            ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (bg != null && bg.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover),
                  )
                else
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3A1F5E), Color(0xFF120A1C)],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(large ? 16 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            room.icon ?? '💬',
                            style: TextStyle(fontSize: large ? 28 : 22),
                          ),
                          if (highlight) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesign.coinGold.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppDesign.coinGold.withValues(alpha: 0.6),
                                ),
                              ),
                              child: const Text(
                                'BENİM ODAM',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppDesign.coinGold,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (room.displayOnline > 0)
                            _OnlinePill(count: room.displayOnline),
                        ],
                      ),
                      SizedBox(height: large ? 20 : 12),
                      Text(
                        room.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: large ? 18 : 15,
                          height: 1.1,
                        ),
                      ),
                      if (room.descTr != null && room.descTr!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          room.descTr!,
                          maxLines: large ? 2 : 1,
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
                              radius: large ? 16 : 13,
                              backgroundImage:
                                  CachedNetworkImageProvider(room.ownerAvatarUrl!),
                            )
                          else
                            CircleAvatar(
                              radius: large ? 16 : 13,
                              child: Icon(Icons.person, size: large ? 18 : 14),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              room.ownerName ?? 'Oda sahibi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: large ? 12 : 11,
                              ),
                            ),
                          ),
                          ..._avatarStack(room.recentUserAvatars),
                          const SizedBox(width: 6),
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
                                  color: AppDesign.accentCyan.withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Katıl',
                                  style: TextStyle(
                                    color: AppDesign.accentCyan.withValues(alpha: 0.95),
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
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05, end: 0);
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
