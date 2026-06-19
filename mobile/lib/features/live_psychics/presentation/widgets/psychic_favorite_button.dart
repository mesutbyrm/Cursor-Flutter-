import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/psychic_favorites_provider.dart';

/// Favori falcı kalp düğmesi.
class PsychicFavoriteButton extends ConsumerWidget {
  const PsychicFavoriteButton({
    super.key,
    required this.tellerId,
    this.iconSize = 22,
    this.color = Colors.white,
  });

  final String tellerId;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(psychicFavoritesProvider);
    final isFavorite = favorites.valueOrNull?.contains(tellerId) == true;
    final loading = favorites.isLoading;

    return IconButton(
      onPressed: loading
          ? null
          : () async {
              final ok = await ref
                  .read(psychicFavoritesProvider.notifier)
                  .toggle(tellerId);
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Favori güncellenemedi')),
                );
              }
            },
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? const Color(0xFFFF4081) : color,
        size: iconSize,
      ),
      tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
    );
  }
}
