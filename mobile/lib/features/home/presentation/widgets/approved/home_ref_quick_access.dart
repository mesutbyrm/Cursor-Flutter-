import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../agency/presentation/providers/agency_providers.dart';
import '../../../../web_parity/domain/feature_catalog.dart';
import '../../navigation/home_cta_navigation.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../theme/home_approved_design.dart';
import '../home_motion_widgets.dart';

/// Referans — Keşfet / Sesli / Tanış / Gold / Ajans hızlı erişim (5 kompakt kart).
/// Ajans kutusu: onaylı ajansı olan «Ajansım»ı, olmayan «Ajans Ol»u görür.
class HomeRefQuickAccess extends ConsumerWidget {
  const HomeRefQuickAccess({super.key});

  static const _actions = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'Keşfet',
      icon: Icons.explore_rounded,
      route: '/shorts',
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    _QuickAccessItem(
      label: 'Sesli Oda',
      icon: Icons.mic_rounded,
      route: '/voice-rooms',
      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    _QuickAccessItem(
      label: 'Tanış & Kaynaş',
      icon: Icons.favorite_rounded,
      route: '/social/tanis-kaynas',
      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
    ),
    _QuickAccessItem(
      label: 'Gold Üyelik',
      icon: Icons.workspace_premium_rounded,
      route: '/premium-membership',
      colors: [Color(0xFFFFD700), Color(0xFFFF8A00)],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAgency = ref.watch(
      approvedAgencyProvider.select((s) => s.isApprovedAgency),
    );
    final items = <_QuickAccessItem>[
      ..._actions,
      _QuickAccessItem(
        label: hasAgency ? 'Ajansım' : 'Ajans Ol',
        icon: Icons.apartment_rounded,
        route: hasAgency ? '/ajans/dashboard' : '/ajans/basvur',
        colors: const [Color(0xFF10B981), Color(0xFF06B6D4)],
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
          // İlk ekranda 5 kutu birebir sığar; yenileri yanında kaydırılır.
          const gap = 6.0;
          final tileW = (c.maxWidth - gap * 4) / 5;
          final extras = <_QuickAccessItem>[
            for (final f in kFeatureCatalog.where((e) => e.onHome))
              _QuickAccessItem(
                label: f.label,
                icon: f.icon,
                route: f.route,
                colors: f.colors,
              ),
            const _QuickAccessItem(
              label: 'Tüm Özellikler',
              icon: Icons.apps_rounded,
              route: '/ozellikler',
              colors: [Color(0xFF475569), Color(0xFF8B5CF6)],
            ),
          ];
          final all = [...items, ...extras];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (var i = 0; i < all.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: tileW,
                    child: CanlifalEntranceFadeSlide(
                      delay: Duration(milliseconds: 40 * (i < 8 ? i : 8)),
                      child: all[i].route == '/premium-membership'
                          ? HomeGoldShimmerBand(
                              child: _QuickAccessTile(item: all[i]),
                            )
                          : _QuickAccessTile(item: all[i]),
                    ),
                  ),
                ],
              ],
            ),
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
  });

  final String label;
  final IconData icon;
  final String route;
  final List<Color> colors;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    return CanlifalPressable(
      onTap: () => pushFromHomeCta(context, item.route),
      child: AspectRatio(
        aspectRatio: 0.92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.colors.first.withValues(alpha: 0.92),
                item.colors.last.withValues(alpha: 0.78),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: item.colors.first.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: Colors.white, size: 20),
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
                      ),
                    ),
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
