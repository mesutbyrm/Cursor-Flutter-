import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../feed/presentation/widgets/discover/discover_platform_stats.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class ProfileBroadcasterStatsPage extends ConsumerWidget {
  const ProfileBroadcasterStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'İstatistikler',
          subtitle: 'Site ve kişisel yayın verileri',
          onRefresh: () async {
            ref.invalidate(platformStatsProvider);
            ref.invalidate(profileStatsProvider);
          },
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              mine.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (s) => ProfileGlass(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Senin yayınların',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _row('Canlı yayın', '${s.liveStreams}'),
                      _row('Beğeni', '${s.likes}'),
                      _row('Takipçi', '${s.followers}'),
                      _row('Hediye jetonu', '${s.earningsJeton}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Site istatistikleri',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              const DiscoverPlatformStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
