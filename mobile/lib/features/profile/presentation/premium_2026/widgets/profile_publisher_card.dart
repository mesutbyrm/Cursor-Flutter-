import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';
import 'profile_action_tile.dart';

/// Yayıncı paneli — genişletilmiş grid.
class ProfilePublisherCard extends StatelessWidget {
  const ProfilePublisherCard({
    super.key,
    this.onHistory,
    this.onSchedule,
    this.onStats,
    this.onEquipment,
    this.onSettings,
    this.onEarnings,
    this.onGifts,
    this.onPkHistory,
    this.onPanel,
  });

  final VoidCallback? onHistory;
  final VoidCallback? onSchedule;
  final VoidCallback? onStats;
  final VoidCallback? onEquipment;
  final VoidCallback? onSettings;
  final VoidCallback? onEarnings;
  final VoidCallback? onGifts;
  final VoidCallback? onPkHistory;
  final VoidCallback? onPanel;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.history_rounded, 'Yayın Geçmişi', onHistory),
      (Icons.insights_rounded, 'İstatistikler', onStats),
      (Icons.event_rounded, 'Yayın Planla', onSchedule),
      (Icons.tune_rounded, 'Yayın Ayarları', onSettings),
      (Icons.mic_external_on_rounded, 'Ekipman', onEquipment),
      (Icons.account_balance_wallet_rounded, 'Gelirler', onEarnings),
      (Icons.card_giftcard_rounded, 'Hediyeler', onGifts),
      (Icons.sports_martial_arts_rounded, 'PK Geçmişi', onPkHistory ?? () => context.push('/pk/history')),
      (Icons.dashboard_rounded, 'Panele Git', onPanel ?? () => context.push('/live/type')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Yayıncı Paneli'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final (icon, label, tap) = items[i];
            return ProfileActionTile(
              icon: icon,
              label: label,
              onTap: tap,
              gradient: [
                ProfilePremiumTheme.neonPurple.withValues(alpha: 0.35),
                ProfilePremiumTheme.deepBg,
              ],
            );
          },
        ),
      ],
    );
  }
}
