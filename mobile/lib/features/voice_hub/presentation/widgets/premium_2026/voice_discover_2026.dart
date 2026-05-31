import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../theme/voice_room_tokens.dart';

/// Keşfet — 2x3 kategori grid + öne çıkan odalar (referans görsel).
class VoiceDiscoverCategories2026 extends StatelessWidget {
  const VoiceDiscoverCategories2026({
    super.key,
    required this.onCategoryTap,
    this.selectedId,
  });

  final ValueChanged<String> onCategoryTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final cats = VoiceRoomTokens.discoverCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [VoiceRoomTokens.neonPink, VoiceRoomTokens.neonPurple],
              ).createShader(b),
              child: const Text(
                'Kategoriler',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: cats.length,
          itemBuilder: (context, i) {
            final c = cats[i];
            final selected = selectedId == c.id;
            return _CategoryCard(
              def: c,
              selected: selected,
              onTap: () => onCategoryTap(c.id),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final VoiceCategoryDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: def.gradient,
            ),
            border: selected
                ? Border.all(color: Colors.white, width: 2)
                : Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: VoiceRoomTokens.neonGlow(def.gradient.first, blur: 14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(def.icon, color: Colors.white, size: 28),
                const Spacer(),
                Text(
                  def.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white,
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

class VoiceFeaturedRooms2026 extends StatelessWidget {
  const VoiceFeaturedRooms2026({
    super.key,
    required this.rooms,
    required this.onRoomTap,
  });

  final List<VoiceRoomEntity> rooms;
  final ValueChanged<VoiceRoomEntity> onRoomTap;

  @override
  Widget build(BuildContext context) {
    final featured = rooms.take(6).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Öne Çıkan Odalar',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return _FeaturedCard(
                room: featured[i],
                onTap: () => onRoomTap(featured[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.room, required this.onTap});

  final VoiceRoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    final online = room.displayOnline;

    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
          child: Ink(
            decoration: VoiceRoomTokens.glassCard(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bg != null && bg.isNotEmpty)
                    CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover)
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4C1D95), Color(0xFF1E1033)],
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (online > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.liveRed.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Canlı Yayında',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          room.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 14, color: AppColors.onlineGreen),
                            const SizedBox(width: 4),
                            Text(
                              VoiceLiveHeader2026Format.count(online),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: VoiceRoomTokens.fabGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Katıl',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
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
    );
  }
}

/// Paylaşılan sayı formatı (header + kart).
abstract final class VoiceLiveHeader2026Format {
  static String count(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
