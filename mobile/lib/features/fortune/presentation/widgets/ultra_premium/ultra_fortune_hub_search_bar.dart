import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/fortune_hub_providers.dart';
import 'ultra_fortune_tokens.dart';

/// Fal hub arama — yerel filtre.
class UltraFortuneHubSearchBar extends ConsumerWidget {
  const UltraFortuneHubSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(fortuneHubSearchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SearchBar(
        hintText: 'Fal türü ara (tarot, kahve, aşk…)',
        leading: Icon(
          Icons.search_rounded,
          color: UltraFortuneTokens.softLilac.withValues(alpha: 0.9),
        ),
        trailing: query.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () =>
                      ref.read(fortuneHubSearchQueryProvider.notifier).state = '',
                ),
              ]
            : null,
        onChanged: (v) =>
            ref.read(fortuneHubSearchQueryProvider.notifier).state = v,
        backgroundColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.06),
        ),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.22),
            ),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white, fontSize: 14),
        ),
        hintStyle: WidgetStateProperty.all(
          TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
