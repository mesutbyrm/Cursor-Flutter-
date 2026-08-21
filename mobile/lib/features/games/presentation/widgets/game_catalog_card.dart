import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../domain/game_models.dart';
import 'game_catalog_assets.dart';

/// Premium oyun kartı — dark glass + violet accent.
class GameCatalogCard extends StatelessWidget {
  const GameCatalogCard({
    super.key,
    required this.game,
    required this.onTap,
    this.activeRooms,
  });

  final GameCatalogItem game;
  final VoidCallback onTap;
  final int? activeRooms;

  @override
  Widget build(BuildContext context) {
    final gradient = GameCatalogAssets.gradientFor(game);
    final imageUrl = GameCatalogAssets.imageUrl(game);
    final roomCount = activeRooms ?? game.activeRoomCount;
    final playerCount = game.onlinePlayerCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: context.colors.surface.withValues(alpha: 0.72),
            border: Border.all(
              color: GameCatalogAssets.violet.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: GameCatalogAssets.violet.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 200),
                          errorWidget: (_, __, ___) => _ArtFallback(
                            game: game,
                            gradient: gradient,
                          ),
                          placeholder: (_, __) => _ArtFallback(
                            game: game,
                            gradient: gradient,
                          ),
                        )
                      else
                        _ArtFallback(game: game, gradient: gradient),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: game.playable
                                ? const Color(0xFF10B981).withValues(alpha: 0.92)
                                : Colors.black54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            game.playable ? 'Oynanabilir' : 'Yakında',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (game.subtitle != null && game.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        game.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (playerCount > 0) ...[
                          Icon(
                            Icons.people_alt_rounded,
                            size: 14,
                            color: context.colors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$playerCount',
                            style: TextStyle(
                              color: context.colors.onSurfaceMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (roomCount > 0) ...[
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 14,
                            color: context.colors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$roomCount oda',
                            style: TextStyle(
                              color: context.colors.onSurfaceMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (game.jetonCost > 0)
                          Text(
                            '${game.jetonCost} Jeton',
                            style: TextStyle(
                              color: context.coinGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.game, required this.gradient});

  final GameCatalogItem game;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          GameCatalogAssets.iconFor(game),
          color: Colors.white.withValues(alpha: 0.92),
          size: 42,
        ),
      ),
    );
  }
}
