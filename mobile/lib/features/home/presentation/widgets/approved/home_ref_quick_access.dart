import 'package:flutter/material.dart';
import '../../navigation/home_cta_navigation.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../theme/home_approved_design.dart';
import '../home_motion_widgets.dart';

/// Referans — Canlı / Sesli / Tanış / Gold hızlı erişim (4 kare kart).
class HomeRefQuickAccess extends StatelessWidget {
  const HomeRefQuickAccess({super.key});

  static const _actions = <_QuickAccessItem>[
    _QuickAccessItem(
      label: 'Canlı Yayın',
      icon: Icons.videocam_rounded,
      route: '/live',
      colors: [Color(0xFFFF2D7A), Color(0xFF8B5CF6)],
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        4,
        HomeApprovedDesign.hPad,
        12,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: CanlifalEntranceFadeSlide(
                delay: Duration(milliseconds: 40 * i),
                child: _actions[i].route == '/premium-membership'
                    ? HomeGoldShimmerBand(
                        child: _QuickAccessTile(item: _actions[i]),
                      )
                    : _QuickAccessTile(item: _actions[i]),
              ),
            ),
          ],
        ],
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
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(HomeApprovedDesign.cardRadius),
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: Colors.white, size: 26),
                const Spacer(),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
