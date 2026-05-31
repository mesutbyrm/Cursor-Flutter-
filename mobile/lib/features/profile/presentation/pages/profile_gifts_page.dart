import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class ProfileGiftsPage extends ConsumerWidget {
  const ProfileGiftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(giftsReceivedSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Hediyelerim',
          subtitle: 'Aldığın hediyeler',
          onRefresh: () async => ref.invalidate(giftsReceivedSummaryProvider),
          body: gifts.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.card_giftcard_outlined,
                  message: 'Henüz hediye alınmadı.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final g = items[i];
                  final isUrl = g.icon.startsWith('http');
                  return ProfileGlass(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isUrl)
                          Image.network(g.icon, height: 36, errorBuilder: (_, _, _) =>
                              Text(g.name, maxLines: 1))
                        else
                          Text(g.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 6),
                        Text(
                          g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'x${g.count}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentPink,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
