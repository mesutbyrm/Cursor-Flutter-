import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../agency/presentation/providers/agency_providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../navigation/home_cta_navigation.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../../core/visual/premium/premium_asset_paths.dart';
import '../../../../../core/visual/premium/premium_glass_image.dart';
import '../../theme/home_approved_design.dart';
import '../home_motion_widgets.dart';

/// Ana sayfa hızlı erişim — iki sıra × 5 görselli kutu.
///
/// 1. sıra: Keşfet · Tanış & Kaynaş · Gold Üyelik · Canlı Falcılar · Tüm Özellikler
/// 2. sıra (role göre): Falcı Panelim/Falcı Ol · Ajansım/Ajans Ol ·
/// Yayıncı Paneli/Yayıncı Ol · Jeton Al · Hediye Yolla
class HomeRefQuickAccess extends ConsumerWidget {
  const HomeRefQuickAccess({super.key});

  static const _row1 = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'Keşfet',
      icon: Icons.explore_rounded,
      route: '/shorts',
      legacyImage: 'home-kesfet.webp',
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    _QuickAccessItem(
      label: 'Tanış & Kaynaş',
      icon: Icons.favorite_rounded,
      route: '/social/tanis-kaynas',
      legacyImage: 'home-tanis-kaynas.webp',
      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
    ),
    _QuickAccessItem(
      label: 'Gold Üyelik',
      icon: Icons.workspace_premium_rounded,
      route: '/premium-membership',
      legacyImage: 'home-gold-uyelik.webp',
      colors: [Color(0xFFFFD700), Color(0xFFFF8A00)],
    ),
    _QuickAccessItem(
      label: 'Canlı Falcılar',
      icon: Icons.videocam_rounded,
      route: '/canli-falcilar',
      legacyImage: 'home-canli-falcilar.webp',
      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
    ),
    _QuickAccessItem(
      label: 'Tüm Özellikler',
      icon: Icons.apps_rounded,
      route: '/ozellikler',
      legacyImage: 'home-tum-ozellikler.webp',
      colors: [Color(0xFF475569), Color(0xFF8B5CF6)],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAgency = ref.watch(
      approvedAgencyProvider.select((s) => s.isApprovedAgency),
    );
    final isTeller = ref.watch(
      approvedPsychicProvider.select((s) => s.isApprovedTeller),
    );
    final loggedIn = ref.watch(
      authControllerProvider.select((s) => s.valueOrNull != null),
    );
    // Ayrı yayıncı rolü yok (canBroadcast varsayılan açık): en az bir yayın
    // geçmişi olan kullanıcı «Yayıncı Paneli»ni görür.
    final isBroadcaster =
        loggedIn &&
        (ref.watch(broadcastHistoryProvider).valueOrNull?.isNotEmpty ?? false);
    final row2 = <_QuickAccessItem>[
      _QuickAccessItem(
        label: isTeller ? 'Falcı Panelim' : 'Falcı Ol',
        icon: Icons.auto_awesome_rounded,
        route: isTeller ? '/falci-panel' : '/falci-ol',
        legacyImage: 'home-falci.webp',
        colors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
      ),
      _QuickAccessItem(
        label: hasAgency ? 'Ajansım' : 'Ajans Ol',
        icon: Icons.apartment_rounded,
        route: hasAgency ? '/ajans/dashboard' : '/ajans/basvur',
        legacyImage: 'home-ajans.webp',
        colors: const [Color(0xFF10B981), Color(0xFF06B6D4)],
      ),
      _QuickAccessItem(
        label: isBroadcaster ? 'Yayıncı Paneli' : 'Yayıncı Ol',
        icon: Icons.live_tv_rounded,
        route: isBroadcaster ? '/profile/broadcaster-stats' : '/live/prep',
        legacyImage: 'home-yayinci.webp',
        colors: const [Color(0xFFFF2D7A), Color(0xFF8B5CF6)],
      ),
      const _QuickAccessItem(
        label: 'Jeton Al',
        icon: Icons.toll_rounded,
        route: '/jeton-store',
        legacyImage: 'home-jeton-al.webp',
        colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
      ),
      const _QuickAccessItem(
        label: 'Hediye Yolla',
        icon: Icons.card_giftcard_rounded,
        route: '/hediye-yolla',
        legacyImage: 'home-hediye-yolla.webp',
        colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        4,
        HomeApprovedDesign.hPad,
        12,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 6.0;
          final tileW = (c.maxWidth - gap * 4) / 5;
          Widget row(List<_QuickAccessItem> items, int delayBase) => Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: tileW,
                  child: CanlifalEntranceFadeSlide(
                    delay: Duration(milliseconds: 40 * (delayBase + i)),
                    child: items[i].route == '/premium-membership'
                        ? HomeGoldShimmerBand(
                            child: _QuickAccessTile(item: items[i]),
                          )
                        : _QuickAccessTile(item: items[i]),
                  ),
                ),
              ],
            ],
          );
          return Column(
            children: [
              row(_row1, 0),
              const SizedBox(height: gap),
              row(row2, 5),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAccessItem {
  const _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.colors,
    required this.legacyImage,
  });

  final String label;
  final IconData icon;
  final String route;
  final List<Color> colors;
  final String legacyImage;

  String get imagePath =>
      PremiumAssetPaths.homeQuickAccess(legacyImage);

  String get legacyImagePath => 'assets/tiles/$legacyImage';
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    return CanlifalPressable(
      onTap: () => pushFromHomeCta(context, item.route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: PremiumGlassImage(
              assetPath: item.imagePath,
              fallbackAssetPath: item.legacyImagePath,
              glowColor: item.colors.first,
              fallbackIcon: item.icon,
              semanticLabel: item.label,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
