import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class ProfileEarningsPage extends ConsumerWidget {
  const ProfileEarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Kazançlarım',
          subtitle: 'Hediye ve onaylı yüklemeler',
          onRefresh: () async => ref.invalidate(profileStatsProvider),
          body: stats.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (s) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                _EarningCard(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Hediyelerden kazanç',
                  value: '${s.earningsJeton} jeton',
                  hint: '${s.giftsReceivedCount} hediye alındı',
                ),
                const SizedBox(height: 12),
                _EarningCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Onaylı yüklemeler',
                  value: '${s.approvedTopUpTotal} birim',
                  hint: 'CFC / jeton talepleri',
                ),
                const SizedBox(height: 12),
                _EarningCard(
                  icon: Icons.live_tv_rounded,
                  label: 'Canlı yayın',
                  value: '${s.liveStreams}',
                  hint: 'Yayın oturumu',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppThemeColors.accentCyan, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
