import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class ProfileBroadcastHistoryPage extends ConsumerWidget {
  const ProfileBroadcastHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(broadcastHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Yayın Geçmişi',
          subtitle: 'Tamamlanan canlı yayınlar',
          onRefresh: () async => ref.invalidate(broadcastHistoryProvider),
          body: history.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.history_rounded,
                  message: 'Henüz yayın geçmişi yok.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final when = item.startedAt != null
                      ? DateFormat('d MMM yyyy · HH:mm', 'tr').format(
                          DateTime.tryParse(item.startedAt!) ?? DateTime.now(),
                        )
                      : '';
                  return ProfileGlass(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.accentPink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                when,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                '${item.giftCount} hediye · ${item.coinsEarned} jeton',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
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
