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
      (Icons.sports_martial_arts_rounded, 'PK Geçmişi', onPkHistory ?? () => context.go('/live')),
      (Icons.dashboard_rounded, 'Panele Git', onPanel ?? () => context.push('/live/type')),
    ];

    // Not: shrinkWrap GridView, CustomScrollView içindeki bir Column'da
    // yüksekliğini yanlış ölçüp içeriğini taşırıp alt bölümlerle üst üste
    // binebiliyordu (yalnızca admin'de görünen bu panelde). Deterministik,
    // kaydırmasız Wrap + sabit oranlı kutular kullanılır.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Yayıncı Paneli'),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            const cols = 3;
            final tileW =
                (constraints.maxWidth - spacing * (cols - 1)) / cols;
            final tileH = tileW / 0.9;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final (icon, label, tap) in items)
                  SizedBox(
                    width: tileW,
                    height: tileH,
                    child: ProfileActionTile(
                      icon: icon,
                      label: label,
                      onTap: tap,
                      gradient: [
                        ProfilePremiumTheme.neonPurple.withValues(alpha: 0.35),
                        ProfilePremiumTheme.deepBg,
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
