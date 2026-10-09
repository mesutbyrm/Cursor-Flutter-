import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../agency/presentation/providers/agency_providers.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../navigation/home_cta_navigation.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
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
      image: 'assets/tiles/home-kesfet.webp',
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    _QuickAccessItem(
      label: 'Tanış & Kaynaş',
      icon: Icons.favorite_rounded,
      route: '/social/tanis-kaynas',
      image: 'assets/tiles/home-tanis-kaynas.webp',
      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
    ),
    _QuickAccessItem(
      label: 'Gold Üyelik',
      icon: Icons.workspace_premium_rounded,
      route: '/premium-membership',
      image: 'assets/tiles/home-gold-uyelik.webp',
      colors: [Color(0xFFFFD700), Color(0xFFFF8A00)],
    ),
    _QuickAccessItem(
      label: 'Canlı Falcılar',
      icon: Icons.videocam_rounded,
      route: '/canli-falcilar',
      image: 'assets/tiles/home-canli-falcilar.webp',
      colors: [Color(0xFFEF4444), Color(0xFFF97316)],
    ),
    _QuickAccessItem(
      label: 'Tüm Özellikler',
      icon: Icons.apps_rounded,
      route: '/ozellikler',
      image: 'assets/tiles/home-tum-ozellikler.webp',
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
        image: 'assets/tiles/home-falci.webp',
        colors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
      ),
      _QuickAccessItem(
        label: hasAgency ? 'Ajansım' : 'Ajans Ol',
        icon: Icons.apartment_rounded,
        route: hasAgency ? '/ajans/dashboard' : '/ajans/basvur',
        image: 'assets/tiles/home-ajans.webp',
        colors: const [Color(0xFF10B981), Color(0xFF06B6D4)],
      ),
      _QuickAccessItem(
        label: isBroadcaster ? 'Yayıncı Paneli' : 'Yayıncı Ol',
        icon: Icons.live_tv_rounded,
        route: isBroadcaster ? '/profile/broadcaster-stats' : '/live/prep',
        image: 'assets/tiles/home-yayinci.webp',
        colors: const [Color(0xFFFF2D7A), Color(0xFF8B5CF6)],
      ),
      const _QuickAccessItem(
        label: 'Jeton Al',
        icon: Icons.toll_rounded,
        route: '/jeton-store',
        image: 'assets/tiles/home-jeton-al.webp',
        colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
      ),
      const _QuickAccessItem(
        label: 'Hediye Yolla',
        icon: Icons.card_giftcard_rounded,
        route: '/gift-send',
        image: 'assets/tiles/home-hediye-yolla.webp',
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
    this.image,
  });

  final String label;
  final IconData icon;
  final String route;
  final List<Color> colors;
  final String? image;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return CanlifalPressable(
      onTap: () => pushFromHomeCta(context, item.route),
      child: AspectRatio(
        aspectRatio: 0.92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.colors.first.withValues(alpha: 0.92),
                item.colors.last.withValues(alpha: 0.78),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: item.colors.first.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.image != null)
                  Image.asset(
                    item.image!,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                // Görsel üstünde okunabilirlik için renkli alt degrade.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amblem görseli ikonu zaten içerir; görsel yoksa ikon.
                      if (item.image == null)
                        Icon(item.icon, color: Colors.white, size: 15),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
